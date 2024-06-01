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
  for [i, unit] in items(s:units)
    if x < 1024
      if x >= 1000
        return '0.9' . s:units[i + 1]
      elseif i == 0
        return x . unit
      elseif x < 10
        return printf("%.1f", x) . unit
      else
        return printf("%.0f", x) . unit
      endif
    endif
    let x = x / 1024.0
  endfor
endfunction


function! myfiler#buffer#render() abort
  setlocal modifiable

  let old_names = myfiler#buffer#is_empty() ? []
        \ : map(range(line('$')), { i -> myfiler#get_basename(i + 1) })
  let dir = myfiler#get_dir()
  let entries = get(b:, 'myfiler_shows_hidden_files', v:false)
        \ ? readdirex(dir)
        \ : readdirex(dir, { entry -> entry.name !~ '^\.' })

  if empty(entries)
    call deletebufline('', 1, line('$'))
    setlocal nomodifiable nomodified
    return
  endif

  if get(b:, 'myfiler_sorts_by_time', v:false)
    call sort(entries, { e1, e2 -> e2.time - e1.time })
  endif
  let new_names = map(copy(entries), { _, entry -> entry.name })

  let new_order = {}
  for name in new_names
    let new_order[name] = len(new_order)
  endfor
  for [i, name] in reverse(items(old_names))
    if get(new_order, name, -1) < 0
      call deletebufline('', i + 1)
      call remove(old_names, i)
    endif
  endfor

  let old_order = {}
  for name in old_names
    let old_order[name] = len(old_order)
  endfor
  for name in new_names
    if get(old_order, name, -1) < 0
      call appendbufline('', line('$'), '')
      call add(old_names, name)
      let old_order[name] = len(old_order)
    endif
  endfor

  let cursor_name = old_names[line('.') - 1]
  let cnum = col('.')

  for [i, name] in items(new_names)
    let lnum = old_order[name] + 1
    let swapped = old_names[i]
    execute (i + 1) . 'move' . lnum
    execute (lnum - 1) . 'move' . i
    let old_names[lnum - 1] = swapped
    let old_names[i] = name
    let old_order[name] = i
    let old_order[swapped] = lnum - 1
  endfor

  execute (new_order[cursor_name]  + 1)
  execute 'normal! 0' . (cnum - 1) . 'l'

  for [i, entry] in items(entries)
    " TODO: Delicate handling cf. getftype()
    let type = entry.type[0] 
    let size = type ==# 'f' ? s:make_fsize_readable(entry.size) : ''
    if get(b:, 'myfiler_shows_detailed_time', v:false)
      let datetime = strftime("%y/%m/%d %H:%M", entry.time) 
      syntax clear myfilerTime
      syntax match myfilerTime '.\{14\}' nextgroup=myfilerSize
    else
      let datetime = strftime("%y/%m/%d", entry.time) 
      syntax clear myfilerTime
      syntax match myfilerTime '.\{8\}' nextgroup=myfilerSize
    endif
    let label = entry.name
    if type ==# 'd'
      let label = label . '/'
    elseif type ==# 'l'
      let resolved = resolve(dir . '/' . entry.name)
      if isdirectory(resolved)
        let suffix = ' /=> ' . resolved . '/'
      elseif filereadable(resolved)
        let suffix = ' /=> ' . resolved
      else
        let suffix = ' /=> (BROKEN LINK)'
      endif
      let label = label . suffix
    endif
    call setline(i + 1, printf("%s %4s  %s", datetime, size, label))
  endfor

  setlocal nomodifiable nomodified
endfunction


let &cpoptions = s:save_cpo
