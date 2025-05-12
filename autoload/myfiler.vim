let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#open(pathStr) abort
  let path = myfiler#path#new(a:pathStr)
  let resolved = path.Resolve()
  if resolved.IsReadble()
    let ext = resolved.GetFileExt()
    let command = get(g:myfiler_open_command, ext, 'edit')
    execute command resolved.ToString()
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
  " TODO: Consider filters
  if !myfiler#filter#shows_hidden_file() && a:name[0] == '.'
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
  execute 'cd' myfiler#util#get_dir().ToString()
endfunction


function! myfiler#execute() abort
  if !myfiler#buffer#is_empty()
    let entry = myfiler#util#get_entry()
    let path = entry.path.ToString()
    call feedkeys(': ' . path . "\<Home>!", 'n')
  endif
endfunction


let &cpoptions = s:save_cpo
