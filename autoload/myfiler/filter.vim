let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#filter#init() abort
  let path = myfiler#util#get_dir().ToString()
  let b:myfiler_shows_hidden_file = get(g:myfiler_default_visibility, path)
endfunction


function! myfiler#filter#shows_hidden_file() abort
  return b:myfiler_shows_hidden_file
endfunction


function! myfiler#filter#toggle() abort
  let b:myfiler_shows_hidden_file = !b:myfiler_shows_hidden_file
endfunction


function! myfiler#filter#get_acceptor() abort
  if b:myfiler_shows_hidden_file
    return { _, entry -> v:true }
  else
    return { _, entry -> entry.name !~ '^\.' }
  endif
endfunction


let &cpoptions = s:save_cpo
