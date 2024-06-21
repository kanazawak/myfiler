let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#entry#create(finfo, dir, is_bookmarked) abort
  let entry = #{
      \ name: a:finfo.name,
      \ size: a:finfo.size,
      \ time: a:finfo.time,
      \ is_bookmarked: a:is_bookmarked
      \ }

  if s:is_link(a:finfo.type)
    let resolved = resolve(fnamemodify(a:dir, ':p') . entry.name)
    if isdirectory(resolved)
      let entry.type = 'linkd'
      let entry.resolved = fnamemodify(resolved, ':p:h')
    elseif filereadable(resolved)
      let entry.type = 'linkf'
      let entry.resolved = resolved
    else
      let entry.type = 'broken'
    endif
  else
    let entry.type = a:finfo.type
  endif

  return entry
endfunction


function! s:is_link(ftype) abort
  return   a:ftype ==# 'link'
      \ || a:ftype ==# 'linkd'
      \ || a:ftype ==# 'junction'
      \ || a:ftype ==# 'reparse'
      \ || a:ftype ==# 'broken'
endfunction


function! myfiler#entry#get_name_with_suffix(entry) abort
  let suffix = a:entry.type ==# 'dir' || a:entry.type ==# 'linkd' ? '/' : ''
  return a:entry.name . suffix
endfunction


let &cpoptions = s:save_cpo
