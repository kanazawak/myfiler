let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:to_path(basename) abort
  let dir = myfiler#path#new(myfiler#get_dir())
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

  let entry = myfiler#get_entry()
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


function! myfiler#operation#move() abort
  let selection = myfiler#selection#get()
  if selection.isEmpty() || selection.bufnr == bufnr()
    return
  endif

  let to_bufnr = bufnr()
  let to_dir = myfiler#path#new(myfiler#get_dir(to_bufnr))

  let moved_name = ''
  for entry in selection.getEntries()
    let name = entry.name
    let from_path = myfiler#path#new(entry.path)
    let to_path = to_dir.Append(name)
    if to_dir.Equals(from_path) || from_path.IsAncestorOf(to_dir)
      call myfiler#util#echoerr("'%s' is an ancestor.", name)
    elseif to_path.Exists()
      call myfiler#util#echoerr("'%s' already exists.", name)
    elseif from_path.Move(to_path)
      call myfiler#util#echoerr("Moving '%s' failed.", name)
    else
      let moved_name = name
    endif
  endfor
  
  if moved_name !=# ''
    let name = moved_name
    call myfiler#selection#clear()
    noautocmd silent execute 'keepjumps buffer' selection.bufnr
    call myfiler#buffer#reload()
    noautocmd silent execute 'keepjumps buffer' to_bufnr
  else
    call myfiler#buffer#reload()
    silent execute 'buffer' selection.bufnr
  endif

  call myfiler#buffer#reload()
  call myfiler#search_name(name)
endfunction


function! myfiler#operation#delete() abort
  if myfiler#buffer#is_empty()
    return
  endif

  let selection = myfiler#selection#get()
  if selection.isEmpty() || selection.bufnr != bufnr()
    call s:delete_single()
  elseif selection.isSingle()
    let name = selection.getNames()[0]
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
  let names = join(a:selection.getNames(), ', ')
  let confirm = s:input('Delete ' . names . ' ? (y/N): ')
  if confirm != 'y'
    return
  endif

  for entry in a:selection.getEntries()
    if delete(entry.path) != 0
      call myfiler#util#echoerr("Deletion of '%s' failed.", entry.name)
    endif
  endfor
  call myfiler#buffer#reload()
endfunction


let &cpoptions = s:save_cpo
