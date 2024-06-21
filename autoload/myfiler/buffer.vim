let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return search('.', 'n') == 0
endfunction


function! myfiler#buffer#init() abort
  call myfiler#view#init()
  call myfiler#buffer#reload()

  setlocal buftype=nowrite
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nowrap
  mapclear <buffer>
  setlocal filetype=myfiler
endfunction


function! myfiler#buffer#reload() abort
  call s:load_data()

  let selection = myfiler#selection#get()
  if selection.bufnr == bufnr()
    call myfiler#selection#clear()
  endif

  call myfiler#view#render()

  if selection.bufnr == bufnr()
    call myfiler#selection#restore(selection)
  endif
endfunction


function! s:load_data() abort
  let dir = myfiler#get_dir()
  let dirinfo = readdirex(dir)

  let bookmark_dirinfo = readdirex(g:myfiler_bookmark_directory)
  let bookmark_dict = {}
  for finfo in bookmark_dirinfo
    let path = fnamemodify(g:myfiler_bookmark_directory, ':p') . finfo.name
    let resolved = fnamemodify(resolve(path), ':p')
    if isdirectory(resolved)
      let resolved = fnamemodify(resolved, ':h')
    endif
    let bookmark_dict[resolved] = v:true
  endfor

  let loaded = []
  for finfo in dirinfo
    let path = fnamemodify(dir, ':p') . finfo.name
    let is_bookmarked = has_key(bookmark_dict, path)
    call add(loaded, myfiler#entry#create(finfo, dir, is_bookmarked))
  endfor
  let b:myfiler_loaded_entries = loaded
endfunction


let &cpoptions = s:save_cpo
