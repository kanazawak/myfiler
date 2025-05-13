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
    call new_path.RenameFrom(old_name)
    let entry.name = new_name
    call myfiler#buffer#reload()
  endif
endfunction


function! myfiler#operation#paste() abort
  let from_path_str = get(g:, 'myfiler_last_copied', '')
  if from_path_str == ''
    return
  endif

  let from_path = myfiler#path#new(from_path_str)
  let name = from_path.GetBasename()
  let to_dir = myfiler#util#get_dir()
  let to_path = to_dir.Append(name)

  if from_path.Equals(to_dir) || from_path.IsAncestorOf(to_dir)
    call myfiler#util#echoerr("'%s' is an ancestor.", name)
  elseif to_path.Exists()
    call myfiler#util#echoerr("'%s' already exists.", name)
  elseif from_path.Move(to_path)
    call myfiler#util#echoerr("Pasting '%s' failed.", name)
  else
    unlet g:myfiler_last_copied
    call myfiler#buffer#reload()
    call myfiler#search_name(name)
    " TODO: reload from_dir buffer?
  endif
endfunction


function! myfiler#operation#delete() abort
  " TODO: ensure exsistence of trashbox
  if myfiler#buffer#is_empty()
    return
  endif

  let entry = myfiler#util#get_entry()
  let name = entry.name
  let from_path = entry.path
  let to_dir = myfiler#path#new(g:myfiler_trashbox_directory)
  let to_path = to_dir.Append(name)

  if from_path.Equals(to_dir)
    call myfiler#util#echoerr("Trashbox can't be deleted.")
  elseif from_path.IsAncestorOf(to_dir)
    call myfiler#util#echoerr("'%s' is an ancestor of the trashbox.", name)
  elseif to_dir.IsAncestorOf(from_path)
    call myfiler#util#echoerr("'%s' is already in the trashbox.", name)
    let g:myfiler_last_copied = from_path.ToString()
  elseif to_path.Exists()
    call myfiler#util#echoerr("'%s' already exists in the trashbox.", name)
  elseif from_path.Move(to_path)
    call myfiler#util#echoerr("Deleting '%s' failed.", name)
  else
    call myfiler#buffer#reload()
    let g:myfiler_last_copied = to_path.ToString()
    " TODO: reload trashbox buffer?
  endif
endfunction


let &cpoptions = s:save_cpo
