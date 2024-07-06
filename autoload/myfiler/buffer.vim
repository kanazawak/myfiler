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
  let bookmark_dir = myfiler#path#new(g:myfiler_bookmark_directory)
  let bookmark_dirinfo = readdirex(g:myfiler_bookmark_directory)
  let bookmark_dict = {}
  for finfo in bookmark_dirinfo
    let link = bookmark_dir.Append(finfo.name)
    let resolved = link.Resolve()
    let bookmark_dict[resolved.ToString()] = v:true
  endfor

  let dir = myfiler#path#new(myfiler#get_dir())
  let dirinfo = readdirex(dir.ToString())

  let loaded = []
  for finfo in dirinfo
    let path = dir.Append(finfo.name)
    let is_bookmarked = has_key(bookmark_dict, path.ToString())
    call add(loaded, myfiler#entry#create(finfo, dir.ToString(), is_bookmarked))
  endfor
  let b:myfiler_loaded_entries = loaded

  call myfiler#view#render()
endfunction


let &cpoptions = s:save_cpo
