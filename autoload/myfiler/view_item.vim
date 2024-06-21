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


function! myfiler#view_item#create_line(entry, max_namelen) abort
  let time = s:get_time_display(a:entry)
  let size = s:get_size_display(a:entry)
  let mark = s:get_mark_display(a:entry)
  let name = s:get_name_display(a:entry)
  let link = s:get_link_display(a:entry, a:max_namelen)
  return time . size . mark . name . link
endfunction


function! s:get_mark_display(entry) abort
  if s:shows_bookmark()
    " TODO: is_bookmarked should be passed by argument
    return a:entry.isBookmarked ? '*' : ' '
  else
    return ''
  endif
endfunction


function! s:get_time_display(entry) abort
  let format =
      \ s:shows_datetime() ? '%y/%m/%d %H:%M ' :
      \ s:shows_date()     ? '%y/%m/%d ' : ''
  return strftime(format, a:entry.time)
endfunction


let s:size_units = ['B', 'K', 'M', 'G', 'T', 'P']
function! s:get_size_display(entry) abort
  if !s:shows_size()
    return ''
  endif

  if !a:entry.meansFile()
     return '     '
  endif

  let x = a:entry.size
  for i in range(len(s:size_units))
    let unit = s:size_units[i]
    if x < 1024
      if x >= 1000
        " Ex. 1000 Bytes => 0.9K
        let str = '0.9' . s:size_units[i + 1]
        break
      elseif i == 0
        " Ex. 999 Bytes => 999B
        let str = x . unit
        break
      elseif x < 10
        " Ex. 2048 KiloBytes => 2.0M
        let str = printf("%.1f", x) . unit
        break
      else
        " Ex. 999.9 MegaBytes => 999M
        let str = printf("%d", float2nr(x)) . unit
        break
      endif
    endif
    let x /= 1024.0
  endfor
  return printf("%4s ", str)
endfunction


function! s:get_name_display(entry) abort
  if !s:shows_last_slash()
    let suffix = ''
  elseif a:entry.isDirectory()
    let suffix = '/'
  elseif a:entry.isLinkToDir() && !s:shows_link()
    let suffix = '/'
  else
    let suffix = ''
  endif
  return a:entry.name . suffix
endfunction


function! s:get_link_display(entry, max_namelen) abort
  if !a:entry.isLink() || !s:shows_link()
    return ''
  endif

  let padding = ''
  if s:aligns_arrow()
    let pad_len = a:max_namelen - strdisplaywidth(a:entry.name)
    let padding = repeat(' ', pad_len)
  endif

  " TODO: relative path from the directory
  let resolved = fnamemodify(get(a:entry, 'resolved'), ':~')
  if a:entry.isLinkToDir() && s:shows_last_slash()
    let resolved .= '/'
  elseif a:entry.isBrokenLink()
    let resolved = '(BROKEN LINK)'
  endif

  return padding . ' /=> ' . resolved
endfunction


function! myfiler#view_item#update(str) abort
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


function! s:bulk_update(array) abort
  let aligns_arrow = s:aligns_arrow()
  let b:myfiler_view_items = a:array
  if aligns_arrow
    let b:myfiler_view_items += ['A']
  endif
endfunction


function! myfiler#view_item#show_all() abort
  let b:myfiler_view_items = ['T', 's', 'b', 'D', 'l']
      \ + (s:aligns_arrow() ? ['A'] : [])
endfunction


function! myfiler#view_item#hide_all() abort
  let b:myfiler_view_items = [] + (s:aligns_arrow() ? ['A'] : [])
endfunction


function! myfiler#view_item#save() abort
  return copy(b:myfiler_view_items)
endfunction


function! myfiler#view_item#restore(saved) abort
  let b:myfiler_view_items = copy(a:saved)
endfunction


let &cpoptions = s:save_cpo
