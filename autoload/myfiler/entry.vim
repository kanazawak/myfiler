let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#entry#create(finfo, dir) abort
  let entry = #{
      \ name: a:finfo.name,
      \ size: a:finfo.size,
      \ time: a:finfo.time
      \ }

  if s:is_link(a:finfo.type)
    let resolved = resolve(fnamemodify(a:dir, ':p') . entry.name)
    if isdirectory(resolved)
      let entry.type = 'linkd'
      let entry.resolved = fnamemodify(resolved, ':p')
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


function! myfiler#entry#compare(e1, e2) abort
  let cmp1 = (a:e2.type ==# 'dir' || a:e2.type ==# 'linkd')
         \ - (a:e1.type ==# 'dir' || a:e1.type ==# 'linkd')
  if cmp1 != 0
    return cmp1
  endif
  if a:e1.name < a:e2.name
    return -1
  elseif a:e1.name > a:e2.name
    return 1
  else
    return 0
  endif
endfunction


function! myfiler#entry#to_line(entry, shows_detailed_time) abort
  let time = s:get_time_display(a:entry, a:shows_detailed_time)
  let size = s:get_size_display(a:entry)
  let name = s:get_name_display(a:entry)
  let link = s:get_link_display(a:entry)
  return printf("%s %4s  %s%s", time, size, name, link)
endfunction


function! s:is_link(ftype) abort
  return   a:ftype ==# 'link'
      \ || a:ftype ==# 'linkd'
      \ || a:ftype ==# 'junction'
      \ || a:ftype ==# 'reparse'
      \ || a:ftype ==# 'broken'
endfunction


let s:time_format_long  = '%y/%m/%d %H:%M'
let s:time_format_short = '%y/%m/%d'
function! s:get_time_display(entry, shows_detailed_time) abort
  let format = a:shows_detailed_time ? s:time_format_long : s:time_format_short
  return strftime(format, a:entry.time) 
endfunction


let s:size_units = ['B', 'K', 'M', 'G', 'T', 'P']
function! s:get_size_display(entry) abort
  if a:entry.type !=# 'file' && a:entry.type !=# 'linkf'
     return ''
   endif

  let x = a:entry.size
  for i in range(len(s:size_units))
    let unit = s:size_units[i]
    if x < 1024
      if x >= 1000
        " Ex. 1000 Bytes => 0.9K
        return '0.9' . s:size_units[i + 1]
      elseif i == 0
        " Ex. 999 Bytes => 999B
        return x . unit
      elseif x < 10
        " Ex. 2048 KiloBytes => 2.0M
        return printf("%.1f", x) . unit
      else
        " Ex. 10240 MegaBytes => 10G
        return printf("%.0f", x) . unit
      endif
    endif
    let x /= 1024.0
  endfor
endfunction


function! s:get_name_display(entry) abort
  let suffix = a:entry.type ==# 'dir' ? '/' : ''
  return a:entry.name . suffix
endfunction


function! s:get_link_display(entry) abort
  if a:entry.type ==# 'linkf' || a:entry.type ==# 'linkd' 
    return ' /=> ' . a:entry.resolved
  elseif a:entry.type == 'broken'
    return ' /=> (BROKEN LINK)'
  else
    return ''
  endif
endfunction


let &cpoptions = s:save_cpo
