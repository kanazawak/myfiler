let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:edit(path_str) abort
  execute 'edit' fnameescape(a:path_str)
endfunction


function! myfiler#open(path_str) abort
  let path = myfiler#path#new(a:path_str)
  let resolved = path.Resolve()
  if resolved.IsReadble()
    let ext = resolved.GetFileExt()
    let Func = get(g:myfiler_open_func, ext, funcref('s:edit'))
    call Func(resolved.ToString())
  else
    call myfiler#util#echoerr("Opening failed.")
  endif
endfunction


function! myfiler#open_current() abort
  if !myfiler#buffer#is_empty()
    let entry = myfiler#util#get_entry()
    call myfiler#open(entry.path.ToString())
  endif
endfunction


function! myfiler#open_dir() abort
  if !myfiler#buffer#is_empty()
    let entry = myfiler#util#get_entry()
    if entry.isDirectory()
      call myfiler#open(entry.path.ToString())
    endif
  endif
endfunction


function! myfiler#search_name(name, updates_jumplist = v:false) abort
  if myfiler#is_hidden(a:name)
    call myfiler#view#toggle_hidden_filter()
  endif

  if myfiler#buffer#is_empty()
    return
  endif

  for lnum in range(1, line('$'))
    if myfiler#util#get_entry(lnum).name ==# a:name
      if a:updates_jumplist
        execute 'normal!' lnum . 'G'
      else
        execute lnum
      endif
      return
    endif
  endfor
endfunction


function! myfiler#is_hidden(name) abort
  if myfiler#filter#shows_hidden_file()
        \ || a:name[0] != '.'
        \ || myfiler#buffer#is_empty()
    return v:false
  endif

  for entry in b:myfiler_loaded_entries
    if entry.name ==# a:name
      return !entry.isBookmarked
    endif
  endfor

  return v:false
endfunction


function! myfiler#open_parent() abort
  let current = myfiler#util#get_dir()
  if !current.IsRoot()
    let parent = current.GetParent()
    call myfiler#open(parent.ToString())
    call myfiler#search_name(current.GetBasename())
  endif
endfunction


function! myfiler#reload() abort
  call myfiler#buffer#reload()
endfunction


function! myfiler#change_directory() abort
  execute 'tcd' myfiler#util#get_dir().ToString()
endfunction


function! myfiler#execute() abort
  if !myfiler#buffer#is_empty()
    let entry = myfiler#util#get_entry()
    let path_str = entry.path.ToString()
    call feedkeys(': ' . path_str . "\<Home>!", 'n')
  endif
endfunction


function! myfiler#toggle_bookmark() abort
  let bookmark_list = readfile(g:myfiler_bookmark_file)
  let bookmark_dict = {}
  for path_str in bookmark_list
    let path = myfiler#path#new(path_str).Resolve()
    let bookmark_dict[path.ToString()] = v:true
  endfor

  let entry = myfiler#util#get_entry()
  let path_str = entry.path.ToString()
  if has_key(bookmark_dict, path_str)
    call filter(bookmark_list, { _, p ->
          \ myfiler#path#new(p).Resolve().ToString() != path_str })
  else
    call add(bookmark_list, fnamemodify(path_str, ':~'))
  endif

  call writefile(bookmark_list, g:myfiler_bookmark_file)
  call myfiler#reload()
endfunction


let &cpoptions = s:save_cpo
