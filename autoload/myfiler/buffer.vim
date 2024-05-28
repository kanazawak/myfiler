let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return search('.', 'n') == 0
endfunction


function! myfiler#buffer#init() abort
  mapclear <buffer>
  call myfiler#buffer#render()
  setlocal buftype=nowrite
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nowrap
  setlocal filetype=myfiler
endfunction


function! myfiler#buffer#render() abort
  let names1 = myfiler#buffer#is_empty() ? []
        \ : map(range(line('$')), { i -> myfiler#get_basename(i + 1) })
  let dir = myfiler#get_dir()
  let names2 = systemlist('ls -A1 ' . shellescape(dir))

  let cmd = 'ls -AgolhD "%y/%m/%d %H:%M" ' . shellescape(dir) . ' | tail +2'
  let details = map(systemlist(cmd), { _, str -> split(str, '\s\+') })

  let lines2 = []
  for i in range(len(names2))
    let array = details[i]
    let type = array[0][0]
    let size = type ==# '-' ? array[2] : ''
    let date = array[3]
    let time = array[4]
    let label = names2[i]
    if type ==# 'l'
      let resolved = resolve(dir . '/' . names2[i])
      if filereadable(resolved) || isdirectory(resolved)
        let label = label . ' /=> ' . resolved
      else
        let label = label . ' /=> (BROKEN LINK)'
      endif
    endif
    call add(lines2, printf("%s %s %5s  %s", date, time, size, label))
  endfor

  setlocal modifiable
  
  " Utilize diff to not disturb cursor positions for same buffer in other windows
  if !empty(names1)
    let hunks = diff(names1, names2, #{ output: 'indices' })
    call sort(hunks, { h1, h2 -> h2.from_idx - h1.from_idx })
    for hunk in hunks
      if hunk.from_count == 0
        call appendbufline('', hunk.from_idx, range(hunk.to_count))
      elseif hunk.to_count == 0
        call deletebufline('', hunk.from_idx + 1, hunk.from_idx + hunk.from_count)
      endif
    endfor
  endif
  call setline(1, lines2)

  setlocal nomodifiable
  setlocal nomodified
endfunction


let &cpoptions = s:save_cpo
