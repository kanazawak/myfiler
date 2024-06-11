let s:save_cpo = &cpoptions
set cpoptions&vim


let s:time_format_long  = '%y/%m/%d %H:%M'
let s:time_format_short = '%y/%m/%d'


function! myfiler#entry#to_line(entry, dir, shows_detailed_time) abort
  let format = a:shows_detailed_time ? s:time_format_long : s:time_format_short
  let time = strftime(format, a:entry.time) 
  let size = a:entry.type =~ '^f' ? s:get_readable_fsize(a:entry.size) : ''
  let label = a:entry.name
  if a:entry.type =~ '^d'
    let label .= '/'
  elseif a:entry.type =~ '^l'
    let resolved = resolve(fnamemodify(a:dir, ':p') . a:entry.name)
    let suffix =
        \ isdirectory(resolved)  ? ' /=> ' . fnamemodify(resolved, ':p') :
        \ filereadable(resolved) ? ' /=> ' . resolved :
        \ ' /=> (BROKEN LINK)'
    let label .= suffix
  endif
  return printf("%s %4s  %s", time, size, label)
endfunction


let s:units = ['B', 'K', 'M', 'G', 'T', 'P']
function! s:get_readable_fsize(bytes) abort
  let x = a:bytes
  for i in range(len(s:units))
    let unit = s:units[i]
    if x < 1024
      if x >= 1000
        " Ex. 1000 Bytes => 0.9K
        return '0.9' . s:units[i + 1]
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


let &cpoptions = s:save_cpo
