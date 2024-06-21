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


let s:shows = { item -> index(b:myfiler_view_items, item) >= 0 }
let s:shows_datetime   = { -> s:shows('T') }
let s:shows_date       = { -> s:shows('t') }
let s:shows_size       = { -> s:shows('s') }
let s:shows_bookmark   = { -> s:shows('b') }
let s:shows_last_slash = { -> s:shows('D') }
let s:shows_link       = { -> s:shows('l') }
let s:aligns_arrow     = { -> s:shows('A') }


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
  let aligns_arrow = s:aligns_arrow()
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


function! myfiler#view#create_line(entry, max_namelen) abort
  let time = s:get_time_display(a:entry)
  let size = s:get_size_display(a:entry)
  let bookmark = s:get_bookmark_display(a:entry)
  let name = s:get_name_display(a:entry)
  let link = s:get_link_display(a:entry, a:max_namelen)
  return printf("%s%s%s%s%s", time, size, bookmark, name, link)
endfunction


function! s:get_bookmark_display(entry) abort
  if s:shows_bookmark()
    " TODO: is_bookmarked should be passed by argument
    return a:entry.is_bookmarked ? '*' : ' '
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

  if a:entry.type !=# 'file' && a:entry.type !=# 'linkf'
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
  elseif a:entry.type ==# 'dir'
    let suffix = '/'
  elseif a:entry.type == 'linkd' && !s:shows_link()
    let suffix = '/'
  else
    let suffix = ''
  endif
  return a:entry.name . suffix
endfunction


function! s:get_link_display(entry, max_namelen) abort
  if !s:shows_link()
    return ''
  endif

  if s:aligns_arrow()
    let pad_len = a:max_namelen - strdisplaywidth(a:entry.name)
    let padding = repeat(' ', pad_len)
  else
    let padding = ''
  endif

  " TODO: relative path from the directory
  let resolved = fnamemodify(get(a:entry, 'resolved'), ':~')

  if a:entry.type ==# 'linkd' && s:shows_last_slash()
    return padding . ' /=> ' . resolved . '/'
  elseif a:entry.type ==# 'linkd' || a:entry.type ==# 'linkf' 
    return padding . ' /=> ' . resolved
  elseif a:entry.type == 'broken'
    return padding . ' /=> (BROKEN LINK)'
  else
    return ''
  endif
endfunction


let &cpoptions = s:save_cpo
