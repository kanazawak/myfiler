let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return search('.', 'n') == 0
endfunction


function! myfiler#buffer#init() abort
  let path = fnamemodify(myfiler#get_dir(), ':p:h')
  call s:init_view_config(path)
  call myfiler#sort#init()

  call myfiler#buffer#render()

  setlocal buftype=nowrite
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nowrap
  mapclear <buffer>
  setlocal filetype=myfiler
endfunction


function! s:init_view_config(path) abort
  let conf = get(g:myfiler_default_view, a:path, 'tsbDl')

  let b:myfiler_view_items =
      \ conf =~# 'T' ? ['T'] :
      \ conf =~# 't' ? ['t'] : []
  let b:myfiler_view_items += conf =~# 'b' ? ['b'] : []
  let b:myfiler_view_items += conf =~# 's' ? ['s'] : []
  let b:myfiler_view_items += conf =~# 'D' ? ['D'] : []
  let b:myfiler_view_items += conf =~# 'l' ? ['l'] : []
  let b:myfiler_view_items += conf =~# 'A' ? ['A'] : []
  let b:myfiler_view_items += conf =~# 'h' ? ['h'] : []
endfunction


function! myfiler#buffer#render() abort
  let selection = myfiler#selection#get()
  if selection.bufnr == bufnr()
    call myfiler#selection#clear()
  endif

  let cnum = col('.')
  setlocal noreadonly modifiable
  let lnum = s:render()
  setlocal readonly nomodifiable nomodified
  call cursor(lnum, cnum)

  if selection.bufnr == bufnr()
    call myfiler#selection#restore(selection)
  endif
endfunction


function! s:render() abort
  let dir = myfiler#get_dir()
  let dirinfo = myfiler#shows_hidden_file()
        \ ? readdirex(dir)
        \ : readdirex(dir, { entry -> entry.name !~ '^\.' })

  let bookmark_dirinfo = readdirex(g:myfiler_bookmark_directory)
  let bookmark_dict = {}
  for finfo in bookmark_dirinfo
    let path = fnamemodify(g:myfiler_bookmark_directory, ':p') . finfo.name
    let resolved = fnamemodify(resolve(path), ':p')
    if isdirectory(resolved)
      let resolved = fnamemodify(resolved, ':h')
    endif
    let bookmark_dict[resolved] = v:true
  endfor

  let new_entries = []
  for finfo in dirinfo
    let path = fnamemodify(dir, ':p') . finfo.name
    let is_bookmarked = has_key(bookmark_dict, path)
    call add(new_entries, myfiler#entry#create(finfo, dir, is_bookmarked))
  endfor

  call sort(new_entries, myfiler#sort#get_comparator())

  let old_entries = get(b:, 'myfiler_entries', [])
  let b:myfiler_entries = new_entries

  let new_lnum = {}
  for lnum in range(1, len(new_entries))
    let new_lnum[new_entries[lnum - 1].name] = lnum
  endfor
  for i in range(len(old_entries) - 1, 0, -1)
    if !get(new_lnum, old_entries[i].name)
      call remove(old_entries, i)
      call deletebufline('', i + 1)
    endif
  endfor
  let cursor_name = empty(old_entries) ? '' : old_entries[line('.') - 1].name

  " NOTE: Vim BUG?
  " Deletion of a line causes
  " cursors at same line of same buffer in other windows 
  " to move (unexpectedly) up

  let aligns_arrow = myfiler#aligns_arrow()
  if aligns_arrow
    let max_len = max(map(copy(new_entries),
        \ { _, e  -> strdisplaywidth(e.name) }))
  endif

  for lnum in range(1, len(new_entries))
    let entry = new_entries[lnum - 1]
    let pad_len = aligns_arrow ? max_len - strdisplaywidth(entry.name) : 0
    let line = myfiler#entry#to_line(entry, pad_len)
    call setline(lnum, line)
  endfor

  return get(new_lnum, cursor_name, 0)
endfunction


let &cpoptions = s:save_cpo
