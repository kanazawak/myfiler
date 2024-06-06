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
  let selection = myfiler#selection#get()
  let is_selected = {}
  if selection.bufnr == bufnr()
    for sel in selection.list
      let is_selected[myfiler#get_basename(sel.lnum)] = v:true
    endfor
    call myfiler#selection#clear()
  endif

  let cnum = col('.')
  setlocal noreadonly modifiable
  let lnum = s:render()
  setlocal readonly nomodifiable nomodified
  call cursor(lnum, cnum)

  if selection.bufnr == bufnr()
    for lnum in range(1, line('$'))
      if get(is_selected, myfiler#get_basename(lnum))
        call myfiler#selection#add(lnum)
      endif
    endfor
  endif
  " NOTE: Vim BUG? command 'move' seems to hide some signs
endfunction


function! s:render() abort
  let dir = myfiler#get_dir()
  let entries = get(b:, 'myfiler_shows_hidden_files')
        \ ? readdirex(dir)
        \ : readdirex(dir, { entry -> entry.name !~ '^\.' })
  if get(b:, 'myfiler_sorts_by_time')
    call sort(entries, { e1, e2 -> e2.time - e1.time })
  endif

  let new_lnum = {}
  for entry in entries
    let new_lnum[entry.name] = len(new_lnum) + 1
  endfor
  for lnum in range(line('$'), 1, -1)
    if !get(new_lnum, myfiler#get_basename(lnum))
      call deletebufline('', lnum)
    endif
  endfor
  let cursor_name = myfiler#get_basename()

  " NOTE: Vim BUG?
  " Deletion of a line causes
  " cursors at same line of same buffer in other windows 
  " to move (unexpectedly) up

  let time_format = get(b:, 'myfiler_shows_detailed_time') ?
        \ '%y/%m/%d %H:%M' : '%y/%m/%d'
  for i in range(len(entries))
    call setline(i + 1, s:create_line(entries[i], dir, time_format))
  endfor

  return get(new_lnum, cursor_name)
endfunction


function! s:create_line(entry, dir, time_format) abort
  " TODO: Delicate handling cf. getftype()
  let time = strftime(a:time_format, a:entry.time) 
  let size = a:entry.type =~ '^f' ? s:get_readable_fsize(a:entry.size) : ''
  let label = a:entry.name
  if a:entry.type =~ '^d'
    let label .= '/'
  elseif a:entry.type =~ '^l'
    let resolved = resolve(a:dir . '/' . a:entry.name)
    let suffix =
        \ isdirectory(resolved)  ? ' /=> ' . resolved . '/' :
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
        return '0.9' . s:units[i + 1]
      elseif i == 0
        return x . unit
      elseif x < 10
        return printf("%.1f", x) . unit
      else
        return printf("%.0f", x) . unit
      endif
    endif
    let x /= 1024.0
  endfor
endfunction


let &cpoptions = s:save_cpo
