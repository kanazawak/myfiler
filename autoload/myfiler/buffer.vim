let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return search('.', 'n') == 0
endfunction


function! myfiler#buffer#init() abort
  let dir = myfiler#get_dir()
  let conf = get(g:myfiler_default_config, dir, 'tsbDl')
  if conf =~# 'T'
    let b:myfiler_time_format = 'long'
  elseif conf =~# 't'
    let b:myfiler_time_format = 'short'
  else
    let b:myfiler_time_format = 'none'
  endif
  let b:myfiler_shows_bookmark     = conf =~# 'b'
  let b:myfiler_shows_size         = conf =~# 's'
  let b:myfiler_shows_last_slash   = conf =~# 'D'
  let b:myfiler_shows_link         = conf =~# 'l'
  let b:myfiler_aligns_arrows      = conf =~# 'A'
  let b:myfiler_shows_hidden_files = conf =~# 'h'

  call myfiler#buffer#render()

  setlocal buftype=nowrite
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nowrap
  mapclear <buffer>
  setlocal filetype=myfiler
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
  let info = get(b:, 'myfiler_shows_hidden_files')
        \ ? readdirex(dir)
        \ : readdirex(dir, { entry -> entry.name !~ '^\.' })

  let new_entries = map(info, { i, finfo -> myfiler#entry#create(finfo, dir) })
  if get(b:, 'myfiler_sorts_by_time')
    call sort(new_entries, { e1, e2 -> e2.time - e1.time })
  else
    call sort(new_entries, funcref('myfiler#entry#compare'))
  endif

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

  let aligns_arrows = get(b:, 'myfiler_aligns_arrows')
  if aligns_arrows
    let max_len = max(map(copy(new_entries),
        \ { _, e  -> strdisplaywidth(e.name) }))
  endif

  let shows_bookmark = get(b:, 'myfiler_shows_bookmark')
  if shows_bookmark
    let dirinfo = readdirex(g:myfiler_bookmark_directory)
    let bookmark_dict = {}
    for finfo in dirinfo
      let path = fnamemodify(g:myfiler_bookmark_directory, ':p') . finfo.name
      let resolved = fnamemodify(resolve(path), ':p')
      if isdirectory(resolved)
        let resolved = fnamemodify(resolved, ':h')
      endif
      let bookmark_dict[resolved] = v:true
    endfor
  endif
  
  for lnum in range(1, len(new_entries))
    let entry = new_entries[lnum - 1]
    let pad_len = aligns_arrows ? max_len - strdisplaywidth(entry.name) : 0
    let is_bookmarked = v:false
    if shows_bookmark
      let path = fnamemodify(dir, ':p') . entry.name
      let is_bookmarked = has_key(bookmark_dict, path)
    endif
    let line = myfiler#entry#to_line(entry, pad_len, is_bookmarked)
    call setline(lnum, line)
  endfor

  return get(new_lnum, cursor_name, 0)
endfunction


let &cpoptions = s:save_cpo
