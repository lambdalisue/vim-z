if has('nvim')
  function! z#_#job#is_available(...) abort
    return call('z#_#job#nvim#is_available', a:000)
  endfunction

  function! z#_#job#start(...) abort
    return call('z#_#job#nvim#start', a:000)
  endfunction

  function! z#_#job#pid(...) abort
    return call('z#_#job#nvim#pid', a:000)
  endfunction

  function! z#_#job#status(...) abort
    return call('z#_#job#nvim#status', a:000)
  endfunction

  function! z#_#job#send(...) abort
    return call('z#_#job#nvim#send', a:000)
  endfunction

  function! z#_#job#close(...) abort
    return call('z#_#job#nvim#close', a:000)
  endfunction

  function! z#_#job#stop(...) abort
    return call('z#_#job#nvim#stop', a:000)
  endfunction

  function! z#_#job#wait(...) abort
    return call('z#_#job#nvim#wait', a:000)
  endfunction
else
  function! z#_#job#is_available(...) abort
    return call('z#_#job#vim#is_available', a:000)
  endfunction

  function! z#_#job#start(...) abort
    return call('z#_#job#vim#start', a:000)
  endfunction

  function! z#_#job#pid(...) abort
    return call('z#_#job#vim#pid', a:000)
  endfunction

  function! z#_#job#status(...) abort
    return call('z#_#job#vim#status', a:000)
  endfunction

  function! z#_#job#send(...) abort
    return call('z#_#job#vim#send', a:000)
  endfunction

  function! z#_#job#close(...) abort
    return call('z#_#job#vim#close', a:000)
  endfunction

  function! z#_#job#stop(...) abort
    return call('z#_#job#vim#stop', a:000)
  endfunction

  function! z#_#job#wait(...) abort
    return call('z#_#job#vim#wait', a:000)
  endfunction
endif
