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
  setlocal noexpandtab
  mapclear <buffer>
  setlocal filetype=myfiler
endfunction


function! myfiler#buffer#reload(bufnr = 0) abort
  if a:bufnr == 0
    call s:reload()
  else
    let current_bufnr = bufnr()
    noautocmd silent execute 'keepjumps buffer' a:bufnr
    call s:reload()
    noautocmd silent execute 'keepjumps buffer' current_bufnr
  endif
endfunction


function! s:reload() abort
  let bookmark_list = readfile(g:myfiler_bookmark_file)
  let bookmark_dict = {}
  for path_str in bookmark_list
    let path = myfiler#path#new(path_str)
    let resolved = path.Resolve()
    let bookmark_dict[resolved.ToString()] = v:true
  endfor

  let dir = myfiler#util#get_dir()
  let dirinfo = readdirex(dir.ToString())

  let loaded = []
  for finfo in dirinfo
    let path = dir.Append(finfo.name)
    let is_bookmarked = has_key(bookmark_dict, path.ToString())
    call add(loaded, myfiler#entry#new(finfo, dir, is_bookmarked))
  endfor
  let b:myfiler_loaded_entries = loaded

  call myfiler#view#render()
endfunction


let &cpoptions = s:save_cpo
