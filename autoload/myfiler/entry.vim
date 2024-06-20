let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#entry#create(finfo, dir, is_bookmarked) abort
  let entry = #{
      \ name: a:finfo.name,
      \ size: a:finfo.size,
      \ time: a:finfo.time,
      \ is_bookmarked: a:is_bookmarked
      \ }

  if s:is_link(a:finfo.type)
    let resolved = resolve(fnamemodify(a:dir, ':p') . entry.name)
    if isdirectory(resolved)
      let entry.type = 'linkd'
      let entry.resolved = fnamemodify(resolved, ':p:h')
    elseif filereadable(resolved)
      let entry.type = 'linkf'
      let entry.resolved = resolved
    else
      let entry.type = 'broken'
    endif
  else
    let entry.type = a:finfo.type
  endif

  return entry
endfunction


function! s:is_link(ftype) abort
  return   a:ftype ==# 'link'
      \ || a:ftype ==# 'linkd'
      \ || a:ftype ==# 'junction'
      \ || a:ftype ==# 'reparse'
      \ || a:ftype ==# 'broken'
endfunction


function! myfiler#entry#to_line(entry, pad_len) abort
  let time = s:get_time_display(a:entry)
  let size = s:get_size_display(a:entry)
  let bookmark = s:get_bookmark_display(a:entry)
  let name = s:get_name_display(a:entry)
  let link = s:get_link_display(a:entry, a:pad_len)
  return printf("%s%s%s%s%s", time, size, bookmark, name, link)
endfunction


function! s:get_bookmark_display(entry) abort
  if myfiler#shows_bookmark()
    return a:entry.is_bookmarked ? '*' : ' '
  else
    return ''
  endif
endfunction


function! s:get_time_display(entry) abort
  let format =
      \ myfiler#shows_datetime() ? '%y/%m/%d %H:%M ' :
      \ myfiler#shows_date()     ? '%y/%m/%d ' : ''
  return strftime(format, a:entry.time) 
endfunction


let s:size_units = ['B', 'K', 'M', 'G', 'T', 'P']
function! s:get_size_display(entry) abort
  if !myfiler#shows_size()
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
  if !myfiler#shows_last_slash()
    let suffix = ''
  elseif a:entry.type ==# 'dir'
    let suffix = '/'
  elseif a:entry.type == 'linkd' && !myfiler#shows_link()
    let suffix = '/'
  else
    let suffix = ''
  endif
  return a:entry.name . suffix
endfunction


function! s:get_link_display(entry, pad_len) abort
  if !myfiler#shows_link()
    return ''
  endif

  let padding = repeat(' ', a:pad_len)
  let resolved = fnamemodify(get(a:entry, 'resolved'), ':~')

  if a:entry.type ==# 'linkf'
    return padding . ' /=> ' . resolved
  elseif a:entry.type ==# 'linkd' 
    if !myfiler#shows_last_slash()
      return padding . ' /=> ' . resolved
    else
      return padding . ' /=> ' . resolved . '/'
    endif
  elseif a:entry.type == 'broken'
    return padding . ' /=> (BROKEN LINK)'
  else
    return ''
  endif
endfunction


let &cpoptions = s:save_cpo
