let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#view_item#init(path) abort
  let conf = get(g:myfiler_default_view, a:path, 'tsbDl')
  let b:myfiler_view_items =
      \ conf =~# 'T' ? ['T'] :
      \ conf =~# 't' ? ['t'] : []
  let b:myfiler_view_items += conf =~# 'b' ? ['b'] : []
  let b:myfiler_view_items += conf =~# 's' ? ['s'] : []
  let b:myfiler_view_items += conf =~# 'D' ? ['D'] : []
  let b:myfiler_view_items += conf =~# 'l' ? ['l'] : []
  let b:myfiler_view_items += conf =~# 'A' ? ['A'] : []
endfunction


let s:enables = { item -> index(b:myfiler_view_items, item) >= 0 }
let s:shows_datetime   = { -> s:enables('T') }
let s:shows_date       = { -> s:enables('t') }
let s:shows_size       = { -> s:enables('s') }
let s:shows_bookmark   = { -> s:enables('b') }
let s:shows_last_slash = { -> s:enables('D') }
let s:shows_link       = { -> s:enables('l') }
let s:aligns_arrow     = { -> s:enables('A') }


function! myfiler#view_item#change(str) abort
  if len(a:str) < 2
    return
  endif
  let sign = a:str[0]
  if sign !=# '-' && sign !=# '+'
    return
  endif
  let item = a:str[1]
  if match('tTsbDlA', item) < 0
    return
  endif

  " NOTE: Use '!=?' so that 't' can delete 'T'
  call filter(b:myfiler_view_items, { _, c -> c !=? item })
  if sign ==# '+'
    call add(b:myfiler_view_items, item)
  endif
endfunction


function! s:bulk_change(array) abort
  let aligns_arrow = s:aligns_arrow()
  let b:myfiler_view_items = a:array
  if aligns_arrow
    let b:myfiler_view_items += ['A']
  endif
endfunction


function! myfiler#view_item#show_all() abort
  call s:bulk_change(['T', 's', 'b', 'D', 'l'])
endfunction


function! myfiler#view_item#hide_all() abort
  call s:bulk_change([])
endfunction


function! myfiler#view_item#save() abort
  return copy(b:myfiler_view_items)
endfunction


function! myfiler#view_item#restore(saved) abort
  let b:myfiler_view_items = copy(a:saved)
endfunction


let &cpoptions = s:save_cpo
