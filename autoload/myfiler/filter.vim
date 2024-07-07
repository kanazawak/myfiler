let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#filter#init() abort
  let path = myfiler#util#get_dir().ToString()
  let b:myfiler_shows_hidden_file = get(g:myfiler_default_visibility, path)
  let b:myfiler_patterns = []
endfunction


function! myfiler#filter#shows_hidden_file() abort
  return b:myfiler_shows_hidden_file
endfunction


function! myfiler#filter#toggle() abort
  let b:myfiler_shows_hidden_file = !b:myfiler_shows_hidden_file
endfunction


function! myfiler#filter#add_pattern(pattern) abort
  let b:myfiler_patterns += [a:pattern]
endfunction


function! myfiler#filter#pop_pattern() abort
  call remove(b:myfiler_patterns, len(b:myfiler_patterns) - 1)
endfunction


function! myfiler#filter#clear_patterns() abort
  let b:myfiler_patterns = []
endfunction


function! s:pattern_acceptor(pattern) abort
  " TODO: smartcase
  return { entry -> entry.getNameWithSuffix() =~ a:pattern }
endfunction


function! s:compose(acceptor1, acceptor2) abort
  return { entry -> a:acceptor1(entry) && a:acceptor2(entry) }
endfunction


function! myfiler#filter#get_acceptor() abort
  if b:myfiler_shows_hidden_file
    let acceptors = [{ _ -> v:true }]
  else
    let acceptors = [{ entry -> entry.name !~ '^\.' }]
  endif
  let acceptors += map(copy(b:myfiler_patterns),
      \ { _, pat -> s:pattern_acceptor(pat) })
  let Composed = reduce(acceptors,
      \ { composed, acceptor -> s:compose(composed, acceptor) })
  return { _, entry -> Composed(entry) }
endfunction


let &cpoptions = s:save_cpo
