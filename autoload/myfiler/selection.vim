let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#selection#add(lnum) abort
  call sign_place(0, '', 'MyFilerSelected', bufnr(), #{ lnum: a:lnum })
endfunction


function! myfiler#selection#delete(id) abort
  call sign_unplace('', #{ id: a:id })
endfunction


function! myfiler#selection#get() abort
  let allinfo = sign_getplaced()
  for bufinfo in allinfo
    call filter(bufinfo.signs, 'v:val.name == "MyFilerSelected"')
  endfor
  call filter(allinfo, '!empty(v:val.signs)')
  if empty(allinfo)
    return #{ bufnr: bufnr(), list: [] }
  endif

  let bufinfo = allinfo[0]
  let list = []
  for sign in bufinfo.signs
    let basename = myfiler#get_basename(sign.lnum, bufinfo.bufnr)
    call add(list, #{ id: sign.id, lnum: sign.lnum, basename: basename })
  endfor
  return #{ bufnr: bufinfo.bufnr, list: list }
endfunction


function! myfiler#selection#clear() abort
  let selection = myfiler#selection#get()
  call sign_unplacelist(selection.list)
endfunction


function! myfiler#selection#restore(selection) abort
  let dict = {}
  for sel in a:selection.list
    let dict[sel.basename] = 1
  endfor
  for lnum in range(1, line('$'))
    let basename = myfiler#get_basename(lnum)
    if get(dict, basename, 0) == 1
      call myfiler#selection#add(lnum)
    endif
  endfor
endfunction


let &cpoptions = s:save_cpo
