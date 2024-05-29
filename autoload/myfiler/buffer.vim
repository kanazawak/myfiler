let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return search('.', 'n') == 0
endfunction


function! myfiler#buffer#init() abort
  mapclear <buffer>
  setlocal filetype=myfiler
  call myfiler#buffer#render()
  setlocal buftype=nowrite
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nowrap
endfunction


let s:units = ['B', 'K', 'M', 'G', 'T', 'P']
function! s:make_fsize_readable(bytes) abort
  let x = a:bytes
  for i in range(len(s:units))
    if x < 1024
      if i == 0
        return x . s:units[0]
      elseif x < 10
        return printf("%.1f", x) . s:units[i]
      else
        return printf("%.0f", x) . s:units[i]
      endif
    endif
    let x = x / 1024.0
  endfor
endfunction


function! myfiler#buffer#render() abort
  let old_names = myfiler#buffer#is_empty() ? []
        \ : map(range(line('$')), { i -> myfiler#get_basename(i + 1) })
  let dir = myfiler#get_dir()
  let entries = readdirex(dir)
  let new_names = map(copy(entries), { _, entry -> entry.name })

  setlocal modifiable
  
  " Utilize diff to not disturb cursor positions (in other windows)
  if !empty(old_names)
    let hunks = diff(old_names, new_names, #{ output: 'indices' })
    call sort(hunks, { h1, h2 -> h2.from_idx - h1.from_idx })
    for hunk in hunks
      if hunk.from_count == 0
        call appendbufline('', hunk.from_idx, range(hunk.to_count))
      elseif hunk.to_count == 0
        call deletebufline('', hunk.from_idx + 1, hunk.from_idx + hunk.from_count)
      endif
    endfor
  endif

  for i in range(len(entries))
    let entry = entries[i]
    " TODO: More delicate handling
    let type = entry.type[0] 
    let size = type ==# 'f' ? s:make_fsize_readable(entry.size) : ''
    let datetime = strftime("%y/%m/%d %H:%M", entry.time) 
    let label = entry.name
    if type ==# 'l'
      let resolved = resolve(dir . '/' . entry.name)
      let suffix = filereadable(resolved) || isdirectory(resolved)
            \ ? ' /=> ' . resolved
            \ : ' /=> (BROKEN LINK)'
      let label = label . suffix
    endif
    call setline(i + 1, printf("%s %5s  %s", datetime, size, label))
  endfor

  setlocal nomodifiable
  setlocal nomodified
endfunction


let &cpoptions = s:save_cpo
