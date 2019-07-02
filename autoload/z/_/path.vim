let s:is_windows = has('win32')
let s:separator = s:is_windows ? '\\' : '/'

if s:is_windows
  function! z#_#path#isabs(path) abort
    return len(a:path) >= 3 && a:path[:2] =~? '\w:\\'
  endfunction

  function! z#_#path#to_slash(path) abort
    return fnamemodify(a:path, 'gs?\\?/?')
  endfunction

  function! z#_#path#from_slash(path) abort
    return fnamemodify(a:path, 'gs?/?\\?')
  endfunction
else
  function! z#_#path#isabs(path) abort
    return a:path[:0] ==# '/'
  endfunction

  function! z#_#path#to_slash(path) abort
    return a:path
  endfunction

  function! z#_#path#from_slash(path) abort
    return a:path
  endfunction
endif

function! z#_#path#join(paths) abort
  return join(a:paths, s:separator)
endfunction

function! z#_#path#split(path) abort
  return split(a:path, s:separator)
endfunction

function! z#_#path#abspath(path) abort
  return z#_#path#isabs(a:path) ? a:path : z#_#os#path#join(getcwd(), a:path)
endfunction
