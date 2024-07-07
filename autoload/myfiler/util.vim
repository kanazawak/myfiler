let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#util#echoerr(...) abort
  echohl Error
  echo call('printf', a:000)
  echohl None
endfunction


function! myfiler#util#normalize(bufname) abort
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
  " Remove trailing path separator
  if isdirectory(path)
    let path = fnamemodify(path, ':h')
  endif

  return path 
endfunction


function! myfiler#util#get_dir() abort
  let pathStr = myfiler#util#normalize(bufname())
  let path = myfiler#path#new(pathStr)

  try
    if !path.Exists()
      echoerr path . ' no longer exists.'
    endif
  endtry
  
  return path
endfunction


function! myfiler#util#get_entry(lnum = 0) abort
  if myfiler#buffer#is_empty()
    throw 'myfiler#get_entry() must not be called when the buffer is empty'
  else
    let lnum = a:lnum > 0 ? a:lnum : line('.')
    return b:myfiler_entries[lnum - 1]
  endif
endfunction


let &cpoptions = s:save_cpo
