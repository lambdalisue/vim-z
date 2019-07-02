" https://github.com/neovim/neovim/blob/f629f83/src/nvim/event/process.c#L24-L26
let s:KILL_TIMEOUT_MS = 2000

function! z#_#job#vim#is_available() abort
  return !has('nvim') && has('patch-8.0.0027')
endfunction

function! z#_#job#vim#start(args, options) abort
  let j = {}
  let jo = {
        \ 'mode': 'raw',
        \ 'timeout': 0,
        \}
  if has('patch-8.1.889')
    let jo['noblock'] = 1
  endif
  if has_key(a:options, 'on_stdout')
    let jo.out_cb = funcref('s:_out_cb', [j, a:options.on_stdout])
  else
    let jo.out_io = 'null'
  endif
  if has_key(a:options, 'on_stderr')
    let jo.err_cb = funcref('s:_err_cb', [j, a:options.on_stderr])
  else
    let jo.err_io = 'null'
  endif
  if has_key(a:options, 'on_exit')
    let jo.exit_cb = funcref('s:_exit_cb', [
          \ j,
          \ get(a:options, 'on_stdout', v:null),
          \ get(a:options, 'on_stderr', v:null),
          \ a:options.on_exit,
          \])
  endif
  if has_key(a:options, 'cwd') && has('patch-8.0.0902')
    let jo.cwd = a:options.cwd
  endif
  let j.__job = job_start(a:args, jo)
  let j.args = a:args
  return j
endfunction

function! z#_#job#vim#pid(job) abort
  return job_info(a:job.__job).process
endfunction

" NOTE:
" On Unix a non-existing command results in "dead" instead
" So returns "dead" instead of "fail" even in non Unix.
function! z#_#job#vim#status(job) abort
  let status = job_status(a:job.__job)
  return status ==# 'fail' ? 'dead' : status
endfunction

" NOTE:
" A Null character (\0) is used as a terminator of a string in Vim.
" Neovim can send \0 by using \n splitted list but in Vim.
" So replace all \n in \n splitted list to ''
function! z#_#job#vim#send(job, data) abort
  let data = type(a:data) == v:t_list
        \ ? join(map(a:data, 'substitute(v:val, "\n", '''', ''g'')'), "\n")
        \ : a:data
  return ch_sendraw(a:job.__job, data)
endfunction

function! z#_#job#vim#close(job) abort
  call ch_close_in(a:job.__job)
endfunction

function! z#_#job#vim#stop(job) abort
  call job_stop(a:job.__job)
  call timer_start(s:KILL_TIMEOUT_MS, { -> job_stop(a:job.__job, 'kill') })
endfunction

function! z#_#job#vim#wait(job, ...) abort
  let timeout = a:0 ? a:1 : v:null
  let timeout = timeout is# v:null ? v:null : timeout / 1000.0
  let start_time = reltime()
  let job = a:job.__job
  try
    while timeout is# v:null || timeout > reltimefloat(reltime(start_time))
      let status = job_status(job)
      if status !=# 'run'
        return status ==# 'dead' ? job_info(job).exitval : -3
      endif
      sleep 1m
    endwhile
  catch /^Vim:Interrupt$/
    call z#_#job#vim#stop(a:job)
    return -2
  endtry
  return -1
endfunction

function! s:_out_cb(job, cb, channel, msg) abort
  call a:cb(a:job, split(a:msg, "\n", 1), 'stdout')
endfunction

function! s:_err_cb(job, cb, channel, msg) abort
  call a:cb(a:job, split(a:msg, "\n", 1), 'stderr')
endfunction

function! s:_exit_cb(job, on_stdout, on_stderr, on_exit, channel, exitval) abort
  " Make sure on_stdout/on_stderr are called prior to on_exit.
  if a:on_stdout isnot# v:null
    let options = {'part': 'out'}
    while ch_status(a:channel, options) ==# 'open'
      sleep 1m
    endwhile
    while ch_status(a:channel, options) ==# 'buffered'
      call s:_out_cb(a:job, a:on_stdout, a:channel, ch_readraw(a:channel, options))
    endwhile
  endif
  if a:on_stderr isnot# v:null
    let options = {'part': 'err'}
    while ch_status(a:channel, options) ==# 'open'
      sleep 1m
    endwhile
    while ch_status(a:channel, options) ==# 'buffered'
      call s:_err_cb(a:job, a:on_stderr, a:channel, ch_readraw(a:channel, options))
    endwhile
  endif
  call a:on_exit(a:job, a:exitval, 'exit')
endfunction

