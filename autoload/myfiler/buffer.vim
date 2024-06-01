let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return search('.', 'n') == 0
endfunction


function! myfiler#buffer#init() abort
  mapclear <buffer>
  setlocal filetype=myfiler
  let b:myfiler_shows_hidden_files = v:false
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

  let shows_hidden = get(b:, 'myfiler_shows_hidden_files', v:false)
  let entries = shows_hidden
        \ ? readdirex(dir)
        \ : readdirex(dir, { entry -> entry.name !~ '^\.' })
  if get(b:, 'myfiler_sorts_by_time', v:false)
    call sort(entries, { e1, e2 -> e2.time - e1.time })
  endif
  let new_names = map(copy(entries), { _, entry -> entry.name })

  let order = {}
  for name in new_names
    let order[name] = len(order)
  endfor

  setlocal modifiable

  let lnum = 1
  while !myfiler#buffer#is_empty() && lnum <= line('$')
    let name = myfiler#get_basename(lnum)
    if get(order, name, -1) < 0
      call deletebufline('', lnum)
    else
      let lnum = lnum + 1
    endif
  endwhile

  let basename = myfiler#get_basename()
  let cnum = col('.')

  " Insertion sort
  for lnum in range(2, line('$'))
    let name1 = myfiler#get_basename(lnum)
    let ord1 = get(order, name1)
    let i = lnum - 1
    while i >= 1
      let name2 = myfiler#get_basename(i)
      let ord2 = get(order, name2)
      if ord2 < ord1
        break
      else
        let i = i - 1
      endif
    endwhile
    if i < lnum - 1
      execute lnum . 'move' . i
    endif
  endfor

  for lnum in range(1, line('$'))
    if myfiler#get_basename(lnum) ==# basename
      execute lnum
      normal! 0
      if cnum > 1
        execute 'normal! ' . (cnum - 1) . 'l'
      endif
      break
    endif
  endfor
  
  if !myfiler#buffer#is_empty()
    for lnum in range(1, len(new_names))
      if lnum > line('$') || myfiler#get_basename(lnum) !=# new_names[lnum - 1]
        call appendbufline('', lnum - 1, '')
      endif
    endfor
  endif
  
  for i in range(len(entries))
    let entry = entries[i]
    " TODO: Delicate handling cf. getftype()
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
