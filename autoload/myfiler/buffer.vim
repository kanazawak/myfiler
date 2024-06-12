let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return empty(get(b:, 'myfiler_entries', []))
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
      let name = myfiler#get_entry(sel.lnum).name
      let is_selected[name] = v:true
    endfor
    call myfiler#selection#clear()
  endif

  let cnum = col('.')
  setlocal noreadonly modifiable
  let lnum = s:render()
  setlocal readonly nomodifiable nomodified
  call cursor(lnum, cnum)

  if selection.bufnr == bufnr()
    for entry in b:myfiler_entries
      if get(is_selected, entry.name)
        call myfiler#selection#add(entry.idx + 1)
      endif
    endfor
  endif
  " NOTE: Vim BUG? command 'move' seems to hide some signs
endfunction


function! s:render() abort
  let dir = myfiler#get_dir()
  let info = get(b:, 'myfiler_shows_hidden_files')
        \ ? readdirex(dir)
        \ : readdirex(dir, { entry -> entry.name !~ '^\.' })
  if get(b:, 'myfiler_sorts_by_time')
    call sort(info, { i1, i2 -> i2.time - i1.time })
  endif
  let new_entries = map(info, { i, finfo -> myfiler#entry#create(finfo, dir, i) })

  let old_entries = get(b:, 'myfiler_entries', [])
  let b:myfiler_entries = new_entries

  let new_lnum = {}
  for entry in new_entries
    let new_lnum[entry.name] = entry.idx + 1
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
  for entry in new_entries
    let line = myfiler#entry#to_line(entry, dir, shows_detailed_time)
    call setline(entry.idx + 1, line)
  endfor

  return get(new_lnum, cursor_name, 0)
endfunction


let &cpoptions = s:save_cpo
