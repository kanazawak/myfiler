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
  let new_entries = get(b:, 'myfiler_shows_hidden_files')
        \ ? readdirex(dir)
        \ : readdirex(dir, { entry -> entry.name !~ '^\.' })
  if get(b:, 'myfiler_sorts_by_time')
    call sort(new_entries, { e1, e2 -> e2.time - e1.time })
  endif

  let old_entries = get(b:, 'myfiler_entries', [])
  let b:myfiler_entries = new_entries

  let new_lnum = {}
  for entry in new_entries
    let new_lnum[entry.name] = len(new_lnum) + 1
  endfor
  for i in range(len(old_entries) - 1, 0, -1)
    if !get(new_lnum, old_entries[i].name)
      call remove(old_entries, i)
      call deletebufline('', i+ 1)
    endif
  endfor
  let cursor_name = empty(old_entries) ? '' : old_entries[line('.') - 1].name

  " NOTE: Vim BUG?
  " Deletion of a line causes
  " cursors at same line of same buffer in other windows 
  " to move (unexpectedly) up

  let shows_detailed_time = get(b:, 'myfiler_shows_detailed_time')
  for i in range(len(new_entries))
    let line = myfiler#entry#to_line(new_entries[i], dir, shows_detailed_time)
    call setline(i + 1, line)
  endfor

  return get(new_lnum, cursor_name)
endfunction


let &cpoptions = s:save_cpo
