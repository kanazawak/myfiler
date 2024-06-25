let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#util#echoerr(...) abort
  echohl Error
  echo call('printf', a:000)
  echohl None
endfunction


function! myfiler#util#resolve(bufname) abort
  " NOTE: fnamemodify('', ':p') returns CWD
  if a:bufname ==# ''
    return ''
  endif
  " Expand '~' to home directory
  let path = expand(a:bufname)
  " Resolve link
  let path = resolve(path)
  " To full path
  let path = fnamemodify(path, ':p')

  return path 
endfunction


let &cpoptions = s:save_cpo
