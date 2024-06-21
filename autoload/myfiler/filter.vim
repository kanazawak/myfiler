let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#filter#init(path) abort
  " TODO: Get default filter
  let b:myfiler_shows_hidden_file = v:true
endfunction


function! myfiler#filter#shows_hidden_file() abort
  return b:myfiler_shows_hidden_file
endfunction


function! myfiler#filter#toggle() abort
  let b:myfiler_shows_hidden_file = !b:myfiler_shows_hidden_file
endfunction


function! myfiler#filter#get_acceptor() abort
  if b:myfiler_shows_hidden_file
    let Acceptor = { _ -> v:true }
  else
    let Acceptor = { entry -> entry.name !~ '^\.' }
  endif
  return { _, entry -> Acceptor(entry) }
endfunction


let &cpoptions = s:save_cpo
