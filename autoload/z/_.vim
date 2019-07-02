let s:name = fnamemodify(expand('<sfile>:p'), ':t:r')

function! z#_#import(path) abort
  let l:prefix = printf('z#%s#%s', s:name, a:path)
  let l:script = printf(
        \ 'autoload/%s.vim',
        \ substitute(l:prefix, '#', '/', 'g')
        \)
  execute printf(
        \ 'runtime! %s',
        \ fnameescape(z#_#path#from_slash(l:script)),
        \)
  let l:fnames = map(
        \ split(execute('function /' . l:prefix), '\n'),
        \ { -> matchstr(v:val, '^function \zs[a-zA-Z0-9_#]\+\ze(') }
        \)
  let l:module = {}
  for l:fname in filter(l:fnames, '!empty(v:val)')
    let l:name = matchstr(l:fname, '.*#\zs[a-zA-Z0-9_]\+')
    let l:module[l:name] = funcref(l:fname)
  endfor
  return l:module
endfunction
