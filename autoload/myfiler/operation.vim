let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:to_path(basename) abort
  let dir = myfiler#util#get_dir()
  return dir.Append(a:basename)
endfunction


function! s:check_duplication(path) abort
  if a:path.Exists()
    call myfiler#util#echoerr("The name already exists.")
    call myfiler#buffer#reload()
    call myfiler#search_name(a:path.GetBasename(), v:true)
    return v:false
  endif
  return v:true
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
    call path.CreateFile()
    call myfiler#buffer#reload()
    call myfiler#search_name(basename)
  endif
endfunction


function! myfiler#operation#new_dir() abort
  let basename = s:input('New directory name: ')
  if empty(basename)
    return
  endif

  let path = s:to_path(basename)
  if s:check_duplication(path)
    call path.CreateDir()
    call myfiler#buffer#reload()
    call myfiler#search_name(basename)
  endif
endfunction


function! myfiler#operation#rename() abort
  if myfiler#buffer#is_empty()
    return
  endif

  let entry = myfiler#util#get_entry()
  let old_name = entry.name
  let new_name = s:input('New name: ', old_name)
  if empty(new_name) || new_name ==# old_name
    return
  endif

  let new_path = s:to_path(new_name)
  if s:check_duplication(new_path)
    if entry.path.Move(new_path)
      call myfiler#util#echoerr("Renaming failed.", name)
    else
      let entry.name = new_name " for search_name
      call myfiler#buffer#reload()
    endif
  endif
endfunction


function! myfiler#operation#copy() abort
  if myfiler#buffer#is_empty()
    return
  endif

  let entry = myfiler#util#get_entry()
  let path = entry.path

  if path.IsDirectory()
    call myfiler#util#echoerr("Direcotries can't be copied.")
  else
    let g:myfiler_last_copied = path.ToString()
    let g:myfiler_copied_by_delete = v:false
  endif
endfunction


function! myfiler#operation#delete() abort
  if myfiler#buffer#is_empty()
    return
  endif

  let entry = myfiler#util#get_entry()
  let name = entry.name
  let from_path = entry.path

  let to_dir = myfiler#path#new(g:myfiler_trashbox_directory)
  if !to_dir.Exists() && to_dir.CreateDir()
    call myfiler#util#echoerr("Creating trashbox failed.")
    return
  endif
  let to_path = to_dir.Append(name)

  if from_path.Equals(to_dir)
    call myfiler#util#echoerr("Trashbox can't be deleted.")
  elseif from_path.IsAncestorOf(to_dir)
    call myfiler#util#echoerr("'%s' is an ancestor of the trashbox.", name)
  elseif to_dir.IsAncestorOf(from_path)
    call myfiler#util#echoerr("'%s' is already in the trashbox.", name)
    let g:myfiler_last_copied = from_path.ToString()
    let g:myfiler_copied_by_delete = v:true
  elseif to_path.Exists()
    call myfiler#util#echoerr("'%s' already exists in the trashbox.", name)
  elseif from_path.Move(to_path)
    call myfiler#util#echoerr("Deleting '%s' failed.", name)
  else
    call myfiler#buffer#reload()
    let g:myfiler_last_copied = to_path.ToString()
    let g:myfiler_copied_by_delete = v:true
    " TODO: reload trashbox buffer?
  endif
endfunction


function! myfiler#operation#paste() abort
  let from_path_str = get(g:, 'myfiler_last_copied', '')
  if from_path_str == ''
    return
  endif

  let from_path = myfiler#path#new(from_path_str)
  let name = from_path.GetBasename()
  if !from_path.Exists()
    call myfiler#util#echoerr("'%s' no longer exists.", name)
    return
  endif

  if g:myfiler_copied_by_delete
    call s:paste_after_delete(from_path)
  else
    call s:paste_after_copy(from_path)
  endif
endfunction


function! s:paste_after_delete(from_path) abort
  let from_path = a:from_path
  let name = from_path.GetBasename()
  let to_dir = myfiler#util#get_dir()
  let to_path = to_dir.Append(name)

  if from_path.Equals(to_dir) || from_path.IsAncestorOf(to_dir)
    call myfiler#util#echoerr("'%s' is an ancestor.", name)
    return
  endif

  while to_path.Exists()
    call myfiler#search_name(name)
    redraw
    let name = s:input('Name conflict. New name: ', name)
    let to_path = to_dir.Append(name)
  endwhile

  if from_path.Move(to_path)
    call myfiler#util#echoerr("Pasting '%s' failed.", name)
  else
    unlet g:myfiler_last_copied
    call myfiler#buffer#reload()
    call myfiler#search_name(name)
    " TODO: reload from_dir buffer?
  endif
endfunction


function! s:paste_after_copy(from_path) abort
  let from_path = a:from_path
  let name = from_path.GetBasename()
  let to_dir = myfiler#util#get_dir()
  let to_path = to_dir.Append(name)

  while to_path.Exists()
    call myfiler#search_name(name)
    redraw
    let name = s:input('Name conflict. New name: ', name)
    let to_path = to_dir.Append(name)
  endwhile

  if from_path.Copy(to_path)
    call myfiler#util#echoerr("Pasting '%s' failed.", name)
  else
    unlet g:myfiler_last_copied
    call myfiler#buffer#reload()
    call myfiler#search_name(name)
  endif
endfunction


let &cpoptions = s:save_cpo
