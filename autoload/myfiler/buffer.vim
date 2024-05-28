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


function! myfiler#buffer#render() abort
  let old_names = myfiler#buffer#is_empty() ? []
        \ : map(range(line('$')), { i -> myfiler#get_basename(i + 1) })
  let dir = myfiler#get_dir()
  let new_names = systemlist('ls -A1 ' . shellescape(dir))

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

  " -A: Omit './', '../', -g: Omit owner, -o: Omit group, -h: Human-friendly size format
  let cmd = 'ls -lAgohD "%y/%m/%d %H:%M" ' . shellescape(dir) . ' | tail +2'
  let details = map(systemlist(cmd), { _, str -> split(str, '\s\+') })

  for i in range(len(new_names))
    let array = details[i]
    let type = array[0][0]
    let size = type ==# '-' ? array[2] : ''
    let date = array[3]
    let time = array[4]
    let label = new_names[i]
    if type ==# 'l'
      let resolved = resolve(dir . '/' . label)
      let suffix = filereadable(resolved) || isdirectory(resolved)
            \ ? ' /=> ' . resolved
            \ : ' /=> (BROKEN LINK)'
      let label = label . suffix
    endif
    call setline(i + 1, printf("%s %s %5s  %s", date, time, size, label))
  endfor

  setlocal nomodifiable
  setlocal nomodified
endfunction


let &cpoptions = s:save_cpo
