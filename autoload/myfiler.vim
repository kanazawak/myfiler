let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#open(path) abort
  let resolved = resolve(a:path)
  if filereadable(resolved) || isdirectory(resolved)
    let ext = fnamemodify(a:path, ':e')
    let command = get(g:myfiler_open_command, ext, 'edit')
    execute command resolved
  else
    call myfiler#util#echoerr("Opening failed.")
  endif
endfunction


function! myfiler#get_dir(bufnr = 0) abort
  let bufnr = a:bufnr > 0 ? a:bufnr : bufnr()
  let path = resolve(bufname(bufnr))
  try
    if !isdirectory(path)
      echoerr path . ' no longer exists.'
    endif
  endtry
  
  " Return full path without tailing path separator
  return fnamemodify(path, ':p:h')
endfunction


function! myfiler#get_entry(lnum = 0) abort
  if myfiler#buffer#is_empty()
    throw 'myfiler#get_entry() must not be called when the buffer is empty'
  else
    let lnum = a:lnum > 0 ? a:lnum : line('.')
    return b:myfiler_entries[lnum - 1]
  endif
endfunction


function! myfiler#open_current() abort
  if !myfiler#buffer#is_empty()
    let path = myfiler#get_entry().path
    call myfiler#open(path)
  endif
endfunction


function! myfiler#open_dir() abort
  if !myfiler#buffer#is_empty()
    let entry = myfiler#get_entry()
    if entry.isDirectory()
      call myfiler#open(entry.path)
    endif
  endif
endfunction


function! myfiler#search_name(name, updates_jumplist = v:false) abort
  if !myfiler#filter#shows_hidden_file() && a:name[0] == '.'
    call myfiler#view#toggle_hidden_filter()
  endif

  if myfiler#buffer#is_empty()
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


" TODO: Rethink about view
function! myfiler#reload() abort
  call myfiler#selection#clear()
  call myfiler#buffer#reload()
endfunction


function! myfiler#toggle_selection(moves_forward) abort
  if myfiler#buffer#is_empty()
    return
  endif

  let selection = myfiler#selection#get()
  if selection.bufnr != bufnr()
    call myfiler#selection#clear()
  endif
  call selection.toggle()

  execute 'normal!' a:moves_forward ? 'j' : 'k'
endfunction


function! myfiler#change_directory() abort
  execute 'cd' myfiler#get_dir()
endfunction


function! myfiler#execute() abort
  if !myfiler#buffer#is_empty()
    let path = myfiler#get_entry().path
    call feedkeys(': ' . path . "\<Home>!", 'n')
  endif
endfunction


let &cpoptions = s:save_cpo
