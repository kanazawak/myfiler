let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#get_dir() abort
  let path = resolve(bufname())
  try
    if !isdirectory(path)
      echoerr path . ' no longer exists.'
    endif
  endtry
  
  " Return full path without tailing path separator
  return fnamemodify(path, ':p:h')
endfunction


function! s:echo_error(message) abort
  echohl Error
  echomsg a:message
  echohl None
endfunction


function! myfiler#get_entry(lnum = 0) abort
  if myfiler#buffer#is_empty()
    return {}
  else
    let lnum = a:lnum > 0 ? a:lnum : line('.')
    return b:myfiler_entries[lnum - 1]
  endif
endfunction


function! myfiler#get_entries() abort
  if myfiler#buffer#is_empty()
    return []
  else
    return b:myfiler_entries
  endif
endfunction


function! s:to_path(basename) abort
  return fnamemodify(myfiler#get_dir(), ':p') . a:basename
endfunction


function! s:get_path() abort
  return myfiler#get_entry().path
endfunction


function! myfiler#open(path) abort
  let resolved = resolve(a:path)
  if filereadable(resolved) || isdirectory(resolved)
    let ext = fnamemodify(a:path, ':e')
    let command = get(g:myfiler_open_command, ext, 'edit')
    execute command fnameescape(resolved)
  else
    call s:echo_error("Opening failed.")
  endif
endfunction


function! myfiler#open_current() abort
  if !myfiler#buffer#is_empty()
    let entry = b:myfiler_entries[line('.') - 1]
    call myfiler#open(entry.path)
  endif
endfunction


function! myfiler#open_dir() abort
  if !myfiler#buffer#is_empty()
    let path = s:get_path()
    if (isdirectory(path))
      call myfiler#open(path)
    endif
  endif
endfunction


function! myfiler#search_name(name, updates_jumplist = v:false) abort
  if !get(b:, 'myfiler_shows_hidden_files') && a:name[0] == '.'
    call myfiler#change_visibility()
  endif

  if myfiler#buffer#is_empty()
    call s:echo_error('hogehoge')
    return
  endif

  for lnum in range(1, line('$'))
    if myfiler#get_entry(lnum).name ==# a:name
      if a:updates_jumplist
        execute 'normal!' lnum . 'G'
      else
        execute lnum
      endif
      return
    endif
  endfor
endfunction


function! myfiler#open_parent() abort
  let current_dir = myfiler#get_dir()
  let parent_dir = fnamemodify(current_dir, ':h')
  if parent_dir !=# current_dir
    call myfiler#open(parent_dir)
    let basename = fnamemodify(current_dir, ':t')
    call myfiler#search_name(basename)
  endif
endfunction


function! myfiler#reload() abort
  call myfiler#selection#clear()
  call myfiler#buffer#render()
endfunction


function! myfiler#toggle_selection(moves_forward) abort
  if myfiler#buffer#is_empty()
    return
  endif

  let selection = myfiler#selection#get()
  if selection.bufnr != bufnr()
    call myfiler#selection#clear()
    let selection = myfiler#selection#get()
  endif

  let lnum = line('.')
  let sel = filter(selection.list, 'v:val.lnum == lnum')
  if empty(sel)
    call myfiler#selection#add(lnum)
  else
    call myfiler#selection#delete(sel[0].id)
  endif
  execute 'normal!' a:moves_forward ? 'j' : 'k'
endfunction


function! myfiler#execute() abort
  if !myfiler#buffer#is_empty()
    let path = s:get_path()
    call feedkeys(': ' . path . "\<Home>!", 'n')
  endif
endfunction

" TODO: Handle visual mode

function! s:check_duplication(path) abort
  if filereadable(a:path) || isdirectory(a:path)
    call s:echo_error("The name already exists.")
    call myfiler#buffer#render()
    let basename = fnamemodify(a:path, ':t')
    call myfiler#search_name(basename, v:true)
    return v:true
  endif
  return v:false
endfunction


function! s:input(prompt, text = "") abort
  let ret = trim(input(a:prompt, a:text))
  call feedkeys(':', 'nx') " TODO: More simple way
  return ret
endfunction


function! myfiler#new_file() abort
  let basename = s:input('New file name: ')
  if empty(basename)
    return
  endif

  let path = s:to_path(basename)
  if s:check_duplication(path)
    return
  endif

  call writefile([''], path, 'b')
  call myfiler#buffer#render()
  call myfiler#search_name(basename)
endfunction


function! myfiler#new_dir() abort
  let basename = s:input('New directory name: ')
  if empty(basename)
    return
  endif

  let path = s:to_path(basename)
  if s:check_duplication(path)
    return
  endif

  call mkdir(path)
  call myfiler#buffer#render()
  call myfiler#search_name(basename)
endfunction


function! myfiler#rename() abort
  if myfiler#buffer#is_empty()
    return
  endif

  let entry = myfiler#get_entry()
  let old_name = entry.name
  let new_name = s:input('New name: ', old_name)
  if empty(new_name) || new_name ==# old_name
    return
  endif

  let new_path = s:to_path(new_name)
  if s:check_duplication(new_path)
    return
  endif
  call rename(entry.path, new_path)

  let entry.name = new_name
  call myfiler#buffer#render()
endfunction


function! myfiler#move() abort
  let selection = myfiler#selection#get()
  if empty(selection.list) || selection.bufnr == bufnr()
    return
  endif

  let to_dir = myfiler#get_dir()
  let to_bufnr = bufnr()

  noautocmd execute 'keepjumps buffer' selection.bufnr
  let from_dir = myfiler#get_dir()

  let messages = []
  let moves = []
  for sel in selection.list
    let entry = myfiler#get_entry(sel.lnum)
    let name = entry.name
    let from_path = entry.path
    let to_path = fnamemodify(to_dir, ':p') . name
    if to_dir ==# from_path || strpart(to_dir, 0, len(from_path) + 1) ==# fnamemodify(from_path, ':p')
      call add(messages, "'" . name . "' is an ancestor of destiation directory.")
    elseif filereadable(to_path) || isdirectory(to_path)
      call add(messages, "'" . name . "' " . "already exists.")
    else
      call add(moves, [from_path, to_path])
    endif
  endfor
  
  if !empty(messages)
    "Update jumplist to return easily to destination directory)
    noautocmd execute 'keepjumps buffer' to_bufnr
    execute 'buffer' selection.bufnr
    redraw

    for message in messages
      call s:echo_error(message)
    endfor
    " TODO: jump
    return
  endif

  for [from_path, to_path] in moves
    call rename(from_path, to_path)
  endfor

  call myfiler#selection#clear()
  call myfiler#buffer#render()
  noautocmd execute 'keepjumps buffer' to_bufnr

    call myfiler#buffer#render()
  call myfiler#search_name(name)
endfunction


function! myfiler#delete() abort
  if myfiler#buffer#is_empty()
    return
  endif

  " TODO: Recursive deletion

  let selection = myfiler#selection#get()
  if empty(selection.list) || selection.bufnr != bufnr()
    call s:delete_single()
  elseif len(selection.list) == 1
    let lnum = selection.list[0].lnum
    execute 'normal! ' . lnum . 'G'
    normal! zz
    redraw
    call s:delete_single()
  else
    let lnums = map(copy(selection.list), { _, sel -> sel.lnum })
    call s:delete_multi(lnums)
  endif
endfunction


function! s:delete_single() abort
  let path = s:get_path()
  let confirm = s:input('Delete ' . path . ' ? (y/N): ')
  if confirm != 'y'
    return
  endif

  " TODO: Handle already deleted file
  if delete(path) != 0
    call s:echo_error('Deletion failed.')
  else
    call myfiler#buffer#render()
  endif
endfunction


function! s:delete_multi(lnums) abort
  let entries = map(copy(a:lnums), { _, lnum -> myfiler#get_entry(lnum)})
  let names = map(copy(entries), { _, entry -> entry.name })
  let confirm = s:input('Delete ' . join(names, ', ') . ' ? (y/N): ')
  if confirm != 'y'
    return
  endif

  for entry in entries
    if delete(entry.path) != 0
      call s:echo_error('Deletion of ' . entry.name . ' failed.')
    endif
  endfor
  call myfiler#buffer#render()
endfunction


function! myfiler#change_visibility() abort
  let shows_hidden_files = get(b:, 'myfiler_shows_hidden_files', v:false)
  let b:myfiler_shows_hidden_files = !shows_hidden_files
  call myfiler#buffer#render()
endfunction


function! myfiler#change_sort() abort
  let sorts_by_time = get(b:, 'myfiler_sorts_by_time', v:false)
  let b:myfiler_sorts_by_time = !sorts_by_time
  call myfiler#buffer#render()
endfunction


function! myfiler#change_time() abort
  let shows_detailed_time = get(b:, 'myfiler_shows_detailed_time', v:false)
  if shows_detailed_time
    if col('.') >= 15
      normal! 6h
    elseif col('.') >= 10
      call cursor('.', 9)
    endif
  endif
  let b:myfiler_shows_detailed_time = !shows_detailed_time
  call myfiler#buffer#render()
  if !shows_detailed_time && col('.') >= 10
    normal! 6l
  endif
endfunction


function! myfiler#change_directory() abort
  execute 'cd' myfiler#get_dir()
endfunction


function! myfiler#yank_path(with_newline) abort
  if myfiler#buffer#is_empty()
    return
  endif

  let yanked = myfiler#get_entry().path
  if a:with_newline
    let yanked .=
        \ &fileformat ==# 'dos' ? "\r\n" :
        \ &fileformat ==# 'unix' ? "\n" : "\r"
  endif

  for i in range(8, 0, -1)
    execute 'let @' . (i + 1) . '=@' . i
  endfor
  let @0 = yanked
  let @" = yanked
endfunction


let &cpoptions = s:save_cpo
