let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#get_dir(bufnr = bufnr()) abort
  " Return full path without '/' at the end
  return resolve(bufname(a:bufnr))
endfunction


function! s:echo_error(message) abort
  echohl Error
  echomsg a:message
  echohl None
endfunction

"TODO: fnameescape

function! myfiler#get_basename(lnum = 0, bufnr = 0) abort
  let bufnr = a:bufnr > 0 ? a:bufnr : bufnr()
  let lnum = a:lnum > 0 ? a:lnum : line('.')
  let line = getbufoneline(bufnr, lnum)
  let match_idx = match(line, '/=>')
  if match_idx >= 24
    return strpart(line, 22, match_idx - 23)
  else
    return strpart(line, 22)
  endif
endfunction


function! s:to_fullpath(basename) abort
  return myfiler#get_dir() . '/' . a:basename
endfunction


function! s:get_cursor_path() abort
  let basename = myfiler#get_basename()
  return s:to_fullpath(basename)
endfunction


function! myfiler#open(path) abort
  " let bufnr = s:find_buffer(a:path)
  " if bufnr >= 0
  "   execute 'buffer' bufnr
  execute 'edit' fnameescape(resolve(a:path))
endfunction


function! myfiler#open_current() abort
  if myfiler#buffer#is_empty()
    return
  endif

  let path = s:get_cursor_path()
  call myfiler#open(path)
endfunction


function! myfiler#open_dir() abort
  if myfiler#buffer#is_empty()
    return
  endif

  let path = s:get_cursor_path()
  if (isdirectory(path))
    call myfiler#open(path)
  endif
endfunction


function! s:search_basename(basename, add_jump = 0) abort
  " TODO: Handle symbolic links
  let pattern = '^.\{22\}' . a:basename . '$'
  call search(pattern, a:add_jump ? 'sw' : 'w')
  normal! zz
endfunction


function! myfiler#open_parent() abort
  let current_dir = myfiler#get_dir()
  let parent_dir = fnamemodify(current_dir, ':h')
  if parent_dir !=# current_dir
    call myfiler#open(parent_dir)
    let basename = fnamemodify(current_dir, ':t')
    call s:search_basename(basename)
  endif
endfunction


function! myfiler#reload() abort
  call myfiler#buffer#render()
  call myfiler#selection#clear()
endfunction


function! myfiler#toggle_selection(moves_forward) abort
  if myfiler#buffer#is_empty()
    return
  endif

  let selection = myfiler#selection#get()
  if selection.bufnr != bufnr()
    call myfiler#selection#clear()
    let selection = #{ bufnr: bufnr(), list: [] }
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
  if myfiler#buffer#is_empty()
    return
  endif

  " TODO: Judge executed or cancelled

  let selection = myfiler#selection#get()
  if empty(selection.list)
    return s:execute_single()
  endif

  if selection.bufnr != bufnr()
    return s:execute_single()
  endif

  if len(selection.list) == 1
    let lnum = selection.list[0].lnum
    execute 'normal! ' . lnum . 'G'
    normal! zz
    redraw
    let path = s:get_cursor_path()
    return s:execute_single(path)
  endif

  call s:execute_multi(selection)
endfunction

" TODO: Handle visual mode

function! s:execute_single(path = '') abort
  call myfiler#selection#clear()
  let path = a:path == '' ? s:get_cursor_path() : a:path
  call feedkeys(': ' . path . "\<Home>!", 'n')
endfunction


function! s:execute_multi(selection) abort
  " TODO: Change cwd temporarily
  let basenames = map(copy(a:selection.list), { _, sel -> sel.basename })
  let joined = join(basenames, ',')
  let dir = myfiler#get_dir()
  let path = dir . '/{' . joined . '}'
  call feedkeys(': ' . path . "\<Home>!", 'n')
  " call myfiler#selection#clear()
endfunction


function! s:check_duplication(path) abort
  if filereadable(a:path) || isdirectory(a:path)
    call s:echo_error("The name already exists.")
    call myfiler#buffer#render()
    let basename = fnamemodify(a:path, ':t')
    call s:search_basename(basename, v:true)
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
  call feedkeys(':', 'nx') " TODO: More simple way
  if empty(basename)
    return
  endif

  let path = s:to_fullpath(basename)
  if s:check_duplication(path)
    return
  endif

  call writefile([''], path, 'b')
  call myfiler#buffer#render()
  call s:search_basename(basename)
endfunction


function! myfiler#new_dir() abort
  let basename = s:input('New directory name: ')
  if empty(basename)
    return
  endif

  let path = s:to_fullpath(basename)
  if s:check_duplication(path)
    return
  endif

  call mkdir(path)
  call myfiler#buffer#render()
  call s:search_basename(basename)
endfunction


function! myfiler#rename() abort
  if myfiler#buffer#is_empty()
    return
  endif

  let old_name = myfiler#get_basename()
  let new_name = s:input('New name: ', old_name)
  if empty(new_name) || new_name ==# old_name
    return
  endif

  let new_path = s:to_fullpath(new_name)
  if s:check_duplication(new_path)
    return
  endif

  let old_path = s:to_fullpath(old_name)
  call rename(old_path, new_path)

  let selection = myfiler#selection#get()
  if selection.bufnr == bufnr()
    call myfiler#selection#clear()
    let sel = filter(copy(selection.list), 'v:val.basename ==# old_name')
    if !empty(sel)
      let sel[0].basename = new_name
    endif
  else
    let selection.list = [] 
  endif
  call myfiler#buffer#render()
  call s:search_basename(new_name)
  call myfiler#selection#restore(selection)
endfunction


function! myfiler#move() abort
  let selection = myfiler#selection#get()
  if empty(selection.list) || selection.bufnr == bufnr()
    return
  endif

  let from_dir = myfiler#get_dir(selection.bufnr)
  let to_dir = myfiler#get_dir()
  " TODO: Confirm
  for sel in selection.list
    let from_path = from_dir . '/' . sel.basename
    let   to_path =   to_dir . '/' . sel.basename
    " TODO: Handle cases ex. /xxx/yyy -> /xxx/yyy/zzz/yyy
    if filereadable(to_path) || isdirectory(to_path)
      call s:echo_error("'" . sel.basename . "' " . "already exists.")
    else
      call rename(from_path, to_path)
    endif
  endfor

  call myfiler#buffer#render()
  call s:search_basename(sel.basename)

  let bufnr = bufnr()
  call myfiler#selection#clear()
  noautocmd execute 'keepjumps buffer' selection.bufnr
  call myfiler#buffer#render()
  noautocmd execute 'keepjumps buffer' bufnr
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
    call s:delete_multi(selection)
  endif
endfunction


function! s:delete_single() abort
  let path = s:get_cursor_path()
  let confirm = s:input('Delete ' . path . ' ? (y/N): ')
  if confirm != 'y'
    return
  endif

  " TODO: Handle already deleted file
  if delete(path) != 0
    call s:echo_error('Deletion failed.')
  else
    call myfiler#selection#clear()
    call myfiler#buffer#render()
  endif
endfunction


function! s:delete_multi(selection) abort
  let basenames = map(copy(a:selection.list), { _, sel -> sel.basename })
  let confirm = s:input('Delete ' . join(basenames, ', ') . ' ? (y/N): ')
  if confirm != 'y'
    return
  endif
  call myfiler#selection#clear()

  for basename in basenames
    let path = s:to_fullpath(basename)
    if delete(path) != 0
      call s:echo_error('Deletion of ' . basename . ' failed.')
    endif
  endfor
  call myfiler#buffer#render()
endfunction


let &cpoptions = s:save_cpo
