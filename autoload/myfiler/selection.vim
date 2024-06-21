let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:add(lnum) abort
  call sign_place(0, '', 'MyFilerSelected', '', #{ lnum: a:lnum })
endfunction


function! s:delete(id) abort
  call sign_unplace('', #{ id: a:id })
endfunction


function! myfiler#selection#toggle(selection) abort
  let lnum = line('.')
  let name = myfiler#get_entry(lnum).name
  let sign_id = get(a:selection._dict, name)
  if sign_id > 0
    call s:delete(sign_id)
  else
    call s:add(lnum)
  endif
endfunction


function! myfiler#selection#is_empty(selection) abort
  return empty(a:selection._dict)
endfunction


function! myfiler#selection#is_single(selection) abort
  return len(a:selection._dict) == 1
endfunction


function! myfiler#selection#get_names(selection) abort
  return keys(a:selection._dict)
endfunction


function! s:get_signinfo() abort
  let allinfo = sign_getplaced()
  for bufinfo in allinfo
    call filter(bufinfo.signs, { _, sign -> sign.name ==# "MyFilerSelected" })
  endfor
  call filter(allinfo, { _, bufinfo -> !empty(bufinfo.signs) })
  if empty(allinfo)
    return #{ bufnr: bufnr(), signs: [] }
  else
    return allinfo[0]
  endif
endfunction


" TODO: clear if insane
function! myfiler#selection#get() abort
  let info = s:get_signinfo()
  if empty(info.signs)
    return #{ bufnr: bufnr(), _dict: {} }
  endif

  let dict = {}
  let entries = getbufvar(info.bufnr, 'myfiler_entries', [])
  for sign in info.signs
    let entry = entries[sign.lnum - 1]
    let dict[entry.name] = sign.id
  endfor
  return #{ bufnr: info.bufnr, _dict: dict }
endfunction


function! myfiler#selection#clear() abort
  let info = s:get_signinfo()
  call sign_unplacelist(info.signs)
  " NOTE: 'signcolumn=auto' seems to not work by the following way
  " sign undefine MyFilerSelected
  " sign define MyFilerSelected text=>>
endfunction


function! myfiler#selection#restore(selection) abort
  if myfiler#buffer#is_empty()
    return
  endif

  for lnum in range(1, line('$'))
    let name = myfiler#get_entry(lnum).name
    if has_key(a:selection._dict, name)
      call s:add(lnum)
    endif
  endfor
endfunction


let &cpoptions = s:save_cpo
