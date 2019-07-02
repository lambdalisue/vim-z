" http://vim-jp.org/blog/2016/03/23/take-care-of-patch-1577.html
function! z#_#job#nvim#is_available() abort
  return has('nvim') && has('nvim-0.2.0')
endfunction

function! z#_#job#nvim#start(args, options) abort
  let j = {}
  let jo = {}
  if has_key(a:options, 'cwd')
    let jo.cwd = a:options.cwd
  endif
  if has_key(a:options, 'on_stdout')
    let jo.on_stdout = funcref(
          \ 's:on_stdout',
          \ [j, a:options.on_stdout],
          \)
  endif
  if has_key(a:options, 'on_stderr')
    let jo.on_stderr = funcref(
          \ 's:on_stderr',
          \ [j, a:options.on_stderr],
          \)
  endif
  let jo.on_exit = funcref(
        \ 's:on_exit',
        \ [j, get(a:options, 'on_exit', { -> 0 })],
        \)
  let j.__job = jobstart(a:args, jo)
  let j.__pid = s:jobpid_safe(j.__job)
  let j.__exitval = v:null
  let j.args = a:args
  return j
endfunction

function! z#_#job#nvim#pid(job) abort
  return a:job.__pid
endfunction

function! z#_#job#nvim#status(job) abort
  sleep 1m
  try
    call jobpid(a:job.__job)
    return 'run'
  catch /^Vim\%((\a\+)\)\=:E900:/
    return 'dead'
  endtry
endfunction

if exists('*chansend') " Neovim 0.2.3
  function! z#_#job#nvim#send(job, data) abort
    return chansend(a:job.__job, a:data)
  endfunction
else
  function! z#_#job#nvim#send(job, data) abort
    return jobsend(a:job.__job, a:data)
  endfunction
endif

if exists('*chanclose') " Neovim 0.2.3
  function! z#_#job#nvim#close(job) abort
    call chanclose(a:job.__job, 'stdin')
  endfunction
else
  function! z#_#job#nvim#close(job) abort
    call jobclose(a:job.__job, 'stdin')
  endfunction
endif

function! z#_#job#nvim#stop(job) abort
  try
    call jobstop(a:job.__job)
  catch /^Vim\%((\a\+)\)\=:E900/
    " NOTE:
    " Vim does not raise exception even the job has already closed so fail
    " silently for 'E900: Invalid job id' exception
  endtry
endfunction

function! z#_#job#nvim#wait(job, ...) abort
  let timeout = a:0 ? a:1 : v:null
  let exitval = timeout is# v:null
        \ ? jobwait([a:job.__job])[0]
        \ : jobwait([a:job.__job], timeout)[0]
  if exitval != -3
    return exitval
  endif
  " Wait until 'on_exit' callback is called
  while a:job.__exitval is# v:null
    sleep 1m
  endwhile
  return a:job.__exitval
endfunction

if has('nvim-0.3.0')
  " Neovim 0.3.0 and over seems to invoke on_stdout/on_stderr with an empty
  " string data when the stdout/stderr channel has closed.
  " It is different behavior from Vim and Neovim prior to 0.3.0 so remove an
  " empty string list to keep compatibility.
  function! s:on_stdout(job, cb, _, data, ...) abort
    if a:data == ['']
      return
    endif
    call a:cb(a:job, a:data, 'stdout')
  endfunction

  function! s:on_stderr(job, cb, _, data, ...) abort
    if a:data == ['']
      return
    endif
    call a:cb(a:job, a:data, 'stderr')
  endfunction
else
  function! s:on_stdout(job, cb, _, data, ...) abort
    call a:cb(a:job, a:data, 'stdout')
  endfunction

  function! s:on_stderr(job, cb, _, data, ...) abort
    call a:cb(a:job, a:data, 'stderr')
  endfunction
endif

function! s:on_exit(job, cb, _, exitval, ...) abort
  let a:job.__exitval = a:exitval
  call a:cb(a:job, a:exitval, 'exit')
endfunction

function! s:jobpid_safe(job) abort
  try
    return jobpid(a:job)
  catch /^Vim\%((\a\+)\)\=:E900:/
    " NOTE:
    " Vim does not raise exception even the job has already closed so fail
    " silently for 'E900: Invalid job id' exception
    return 0
  endtry
endfunction
