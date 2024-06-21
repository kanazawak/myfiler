let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:to_path(basename) abort
  return fnamemodify(myfiler#get_dir(), ':p') . a:basename
endfunction


function! s:check_duplication(path) abort
  if filereadable(a:path) || isdirectory(a:path)
    call myfiler#util#echoerr("The name already exists.")
    call myfiler#buffer#reload()
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


function! myfiler#operation#new_file() abort
  let basename = s:input('New file name: ')
  if empty(basename)
    return
  endif

  let path = s:to_path(basename)
  if s:check_duplication(path)
    return
  endif

  call writefile([''], path, 'b')
  call myfiler#buffer#reload()
  call myfiler#search_name(basename)
endfunction


function! myfiler#operation#new_dir() abort
  let basename = s:input('New directory name: ')
  if empty(basename)
    return
  endif

  let path = s:to_path(basename)
  if s:check_duplication(path)
    return
  endif

  call mkdir(path)
  call myfiler#buffer#reload()
  call myfiler#search_name(basename)
endfunction


function! myfiler#operation#rename() abort
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

  let old_path = s:to_path(old_name)
  call rename(old_path, new_path)

  let entry.name = new_name
  call myfiler#buffer#reload()
endfunction


function! myfiler#operation#move() abort
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
      call myfiler#util#echoerr(message)
    endfor
    " TODO: jump
    return
  endif

  for [from_path, to_path] in moves
    call rename(from_path, to_path)
  endfor

  call myfiler#selection#clear()
  call myfiler#buffer#reload()
  noautocmd execute 'keepjumps buffer' to_bufnr

  call myfiler#buffer#reload()
  call myfiler#search_name(name)
endfunction


function! myfiler#operation#delete() abort
  if myfiler#buffer#is_empty()
    return
  endif

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
  let path = myfiler#get_entry().path
  let confirm = s:input('Delete ' . path . ' ? (y/N): ')
  if confirm != 'y'
    return
  endif

  if delete(path) != 0
    call myfiler#util#echoerr('Deletion failed.')
  else
    call myfiler#buffer#reload()
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
      call myfiler#util#echoerr('Deletion of ' . name . ' failed.')
    endif
  endfor
  call myfiler#buffer#reload()
endfunction


function! myfiler#operation#add_bookmark() abort
  let entry = myfiler#get_entry()
  let path = entry.path
  let dir = g:myfiler_bookmark_directory
  let linkpath = fnamemodify(dir, ':p') . entry.name
  let command = 'ln -s '
  call system(command . shellescape(path) . ' ' . shellescape(linkpath))
  if v:shell_error
    call myfiler#util#echoerr('Adding bookmark failed.')
  else
    call myfiler#buffer#reload()
    " TODO: rerender bookmark directory
  endif
endfunction


let &cpoptions = s:save_cpo
