let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#view#create_line(entry, max_namelen) abort
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


let &cpoptions = s:save_cpo
