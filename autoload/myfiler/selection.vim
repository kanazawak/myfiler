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
    call add(list, #{ id: sign.id, lnum: sign.lnum })
  endfor
  return #{ bufnr: bufinfo.bufnr, list: list }
  " return map(copy(bufinfo.signs), { _, sign -> #{ id: sign.id, lnum: sign.lnum } })
endfunction


function! myfiler#selection#clear() abort
  let selection = myfiler#selection#get()
  call sign_unplacelist(selection.list)
  " TODO: Handle signcolumn behavior
  " sign undefine MyFilerSelected
  " sign define MyFilerSelected text=>>
endfunction


let &cpoptions = s:save_cpo
