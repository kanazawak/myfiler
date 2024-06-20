let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#view#init(path) abort
  let conf = get(g:myfiler_default_view, a:path, 'tsbDl')
  let b:myfiler_view_items =
      \ conf =~# 'T' ? ['T'] :
      \ conf =~# 't' ? ['t'] : []
  let b:myfiler_view_items += conf =~# 'b' ? ['b'] : []
  let b:myfiler_view_items += conf =~# 's' ? ['s'] : []
  let b:myfiler_view_items += conf =~# 'D' ? ['D'] : []
  let b:myfiler_view_items += conf =~# 'l' ? ['l'] : []
  let b:myfiler_view_items += conf =~# 'A' ? ['A'] : []
  let b:myfiler_view_items += conf =~# 'h' ? ['h'] : []
endfunction


function! myfiler#view#shows_datetime() abort
  return index(b:myfiler_view_items, 'T') >= 0
endfunction


function! myfiler#view#shows_date() abort
  return index(b:myfiler_view_items, 't') >= 0
endfunction


function! myfiler#view#shows_size() abort
  return index(b:myfiler_view_items, 's') >= 0
endfunction


function! myfiler#view#shows_bookmark() abort
  return index(b:myfiler_view_items, 'b') >= 0
endfunction


function! myfiler#view#shows_last_slash() abort
  return index(b:myfiler_view_items, 'D') >= 0
endfunction


function! myfiler#view#shows_link() abort
  return index(b:myfiler_view_items, 'l') >= 0
endfunction


function! myfiler#view#aligns_arrow() abort
  return index(b:myfiler_view_items, 'A') >= 0
endfunction


function! myfiler#view#shows_hidden_file() abort
  return index(b:myfiler_view_items, 'h') >= 0
endfunction


function! myfiler#view#change(str) abort
  if len(a:str) < 2
    return
  endif
  let sign = a:str[0]
  if sign !=# '-' && sign !=# '+' && sign !=# '!'
    return
  endif
  let item = a:str[1]
  if match('tTsbDlAh', item) < 0
    return
  endif

  " NOTE: Use '!=' instead of '!=#' so that 't' can delete 'T'
  let old_len = len(b:myfiler_view_items)
  call filter(b:myfiler_view_items, { _, c -> c != item })
  let new_len = len(b:myfiler_view_items)

  if sign ==# '+'
    call add(b:myfiler_view_items, item)
  elseif sign ==# '!'  " Toggle 
    if new_len == old_len
      call add(b:myfiler_view_items, item)
    endif
  endif
endfunction


function! s:bulk_change(array) abort
  let aligns_arrow = myfiler#view#aligns_arrow()
  let shows_hidden_file = myfiler#view#shows_hidden_file()
  let b:myfiler_view_items = a:array
  if aligns_arrow
    let b:myfiler_view_items += ['A']
  endif
  if shows_hidden_file
    let b:myfiler_view_items += ['b']
  endif
endfunction


function! myfiler#view#show_all() abort
  call s:bulk_change(['T', 's', 'b', 'D', 'l'])
endfunction


function! myfiler#view#hide_all() abort
  call s:bulk_change([])
endfunction


let &cpoptions = s:save_cpo
