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


function! s:get_entry(lnum = 0) abort
  if myfiler#buffer#is_empty()
    return {}
  else
    let lnum = a:lnum > 0 ? a:lnum : line('.')
    return b:myfiler_entries[lnum - 1]
  endif
endfunction


function! myfiler#get_name(lnum = 0) abort
  if myfiler#buffer#is_empty()
    return ''
  else
    let entry = s:get_entry(a:lnum)
    return entry.name
  endif
endfunction


function! s:to_path(basename) abort
  return fnamemodify(myfiler#get_dir(), ':p') . a:basename
endfunction


function! s:get_path() abort
  let basename = myfiler#get_name()
  return s:to_path(basename)
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
    let path = s:get_path()
    call myfiler#open(path)
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
    return
  endif

  for lnum in range(1, line('$'))
    if myfiler#get_name(lnum) ==# a:name
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
  endif
  call myfiler#selection#toggle(selection)

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

  let entry = s:get_entry()
  let old_name = entry.name
  let new_name = s:input('New name: ', old_name)
  if empty(new_name) || new_name ==# old_name
    return
  endif

  let new_path = s:to_path(new_name)
  if s:check_duplication(new_path)
    return
  endif

  let old_path = s:to_path(old_name)
  call rename(old_path, new_path)

  let entry.name = new_name
  call myfiler#buffer#render()
endfunction


function! myfiler#move() abort
  let selection = myfiler#selection#get()
  if myfiler#selection#is_empty(selection) || selection.bufnr == bufnr()
    return
  endif

  let to_dir = myfiler#get_dir()
  let to_bufnr = bufnr()

  noautocmd execute 'keepjumps buffer' selection.bufnr
  let from_dir = myfiler#get_dir()

  let messages = []
  let moves = []
  let names = myfiler#selection#get_names(selection)
  for name in names
    let from_path = fnamemodify(from_dir, ':p') . name
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
  if myfiler#selection#is_empty(selection) || selection.bufnr != bufnr()
    call s:delete_single()
  elseif myfiler#selection#is_single(selection)
    let name = myfiler#selection#get_names(selection)[0]
    call myfiler#search_name(name, v:true)
    redraw
    call s:delete_single()
  else
    call s:delete_multi(selection)
  endif
endfunction


function! s:delete_single() abort
  let path = s:get_path()
  let confirm = s:input('Delete ' . path . ' ? (y/N): ')
  if confirm != 'y'
    return
  endif

  if delete(path) != 0
    call s:echo_error('Deletion failed.')
  else
    call myfiler#buffer#render()
  endif
endfunction


function! s:delete_multi(selection) abort
  let names = myfiler#selection#get_names(a:selection)
  let confirm = s:input('Delete ' . join(names, ', ') . ' ? (y/N): ')
  if confirm != 'y'
    return
  endif

  let path_prefix = fnamemodify(myfiler#get_dir(), ':p')
  for name in names
    let path = path_prefix . name
    if delete(path) != 0
      call s:echo_error('Deletion of ' . name . ' failed.')
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


function! myfiler#change_bookmark_visibility(bool) abort
  let b:myfiler_shows_bookmark = a:bool
  call myfiler#buffer#render()
endfunction


let s:time_formats = ['none', 'short', 'long']
function! myfiler#change_time_format(diff) abort
  let time_format = get(b:, 'myfiler_time_format', 'short')
  let idx = match(s:time_formats, time_format)
  let idx = max([min([idx + a:diff, 2]), 0])
  let b:myfiler_time_format = s:time_formats[idx]
  call myfiler#buffer#render()
endfunction


function! myfiler#change_size_visibility(bool) abort
  let b:myfiler_hides_size = a:bool
  call myfiler#buffer#render()
endfunction


function! myfiler#change_link_visibility(bool) abort
  let b:myfiler_hides_link = a:bool
  call myfiler#buffer#render()
endfunction


function! myfiler#change_last_slash_visibility(bool) abort
  let b:myfiler_hides_last_slash = a:bool
  call myfiler#buffer#render()
endfunction


function! myfiler#hide_all() abort
  let b:myfiler_shows_bookmark = v:false
  let b:myfiler_time_format = 'none'
  let b:myfiler_hides_size = v:true
  let b:myfiler_hides_link = v:true
  let b:myfiler_hides_last_slash = v:true
  call myfiler#buffer#render()
endfunction


function! myfiler#show_all() abort
  let b:myfiler_shows_bookmark = v:true
  let b:myfiler_time_format = 'long'
  let b:myfiler_hides_size = v:false
  let b:myfiler_hides_link = v:false
  let b:myfiler_hides_last_slash = v:false
  call myfiler#buffer#render()
endfunction


function! myfiler#change_arrow_alignment(bool) abort
  let b:myfiler_aligns_arrows = a:bool
  call myfiler#buffer#render()
endfunction


function! myfiler#change_directory() abort
  execute 'cd' myfiler#get_dir()
endfunction


function! myfiler#add_bookmark() abort
  let path = s:get_path()
  let name = fnamemodify(path, ':t')
  let linkpath = fnamemodify(g:myfiler_bookmark_directory, ':p') . name
  let command = 'ln -s '
  call system(command . shellescape(path) . ' ' . shellescape(linkpath))
  if v:shell_error
    call s:echo_error('Adding bookmark failed.')
  else
    call myfiler#buffer#render()
  endif
endfunction


let &cpoptions = s:save_cpo
