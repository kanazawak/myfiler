let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#get_dir(bufnr = bufnr()) abort
  " Return full path without '/' at the end
  return resolve(fnamemodify(resolve(bufname(a:bufnr)), ':p'))
endfunction


function! s:echo_error(message) abort
  echohl Error
  echomsg a:message
  echohl None
endfunction


function! myfiler#get_basename(lnum = 0) abort
  let lnum = a:lnum > 0 ? a:lnum : line('.')
  let line = getbufoneline('', lnum)
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
  let resolved = resolve(a:path)
  if filereadable(resolved) || isdirectory(resolved)
    execute 'edit' fnameescape(resolved)
  else
    call s:echo_error("Opening lailed.")
  endif
endfunction


function! myfiler#open_current() abort
  if !myfiler#buffer#is_empty()
    let path = s:get_cursor_path()
    call myfiler#open(path)
  endif
endfunction


function! myfiler#open_dir() abort
  if !myfiler#buffer#is_empty()
    let path = s:get_cursor_path()
    if (isdirectory(path))
      call myfiler#open(path)
    endif
  endif
endfunction


function! s:search_basename(basename, updates_jumplist = v:false) abort
  for lnum in range(1, line('$'))
    if myfiler#get_basename(lnum) == a:basename
      break
    endif
  endfor
  if a:updates_jumplist
    execute 'normal!' lnum . 'G'
  else
    execute lnum
  endif
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
    let path = s:get_cursor_path()
    call feedkeys(': ' . path . "\<Home>!", 'n')
  endif
endfunction

" TODO: Handle visual mode

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
  let selected = {}
  if selection.bufnr == bufnr()
    for sel in selection.list
      let name = myfiler#get_basename(sel.lnum)
      if name ==# old_name
        let selected[new_name] = v:true
      else
        let selected[name] = v:true
      endif
    endfor
    call myfiler#selection#clear()
  endif

  call myfiler#buffer#render()
  for lnum in range(1, line('$'))
    let basename = myfiler#get_basename(lnum)
    if get(selected, basename, v:false)
      call myfiler#selection#add(lnum)
    endif
  endfor
  call s:search_basename(new_name)
endfunction


function! myfiler#move() abort
  let selection = myfiler#selection#get()
  if empty(selection.list) || selection.bufnr == bufnr()
    return
  endif
  call myfiler#selection#clear()

  let to_dir = myfiler#get_dir()
  let to_bufnr = bufnr()

  noautocmd execute 'keepjumps buffer' selection.bufnr
  let from_dir = myfiler#get_dir()
  " let basenames = map(copy(selection.list),
  "       \ { _, sel -> myfiler#get_basename(sel.lnum) })

  " TODO: Confirm
  for sel in selection.list
    let basename = myfiler#get_basename(sel.lnum)
    let from_path = from_dir . '/' . basename
    let   to_path =   to_dir . '/' . basename
    " TODO: Handle cases ex. /xxx/yyy -> /xxx/yyy/zzz/yyy
    if filereadable(to_path) || isdirectory(to_path)
      call s:echo_error("'" . basename . "' " . "already exists.")
    else
      call rename(from_path, to_path)
    endif
  endfor

  call myfiler#buffer#render()
  noautocmd execute 'keepjumps buffer' to_bufnr

  call myfiler#buffer#render()
  call s:search_basename(basename)
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


function! s:delete_multi(lnums) abort
  let basenames = map(copy(a:lnums), { _, lnum -> myfiler#get_basename(lnum) })
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
