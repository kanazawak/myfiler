let s:save_cpo = &cpoptions
set cpoptions&vim


" Prototype-based OOP
let s:Entry = {}


function! myfiler#entry#create(finfo, dir, is_bookmarked) abort
  let entry = deepcopy(s:Entry)
  let entry.name = a:finfo.name
  let entry.path = fnamemodify(a:dir, ':p') . entry.name
  let entry.size = a:finfo.size
  let entry.time = a:finfo.time
  let entry.isBookmarked = a:is_bookmarked

  if s:is_link(a:finfo.type)
    let resolved = resolve(entry.path)
    if isdirectory(resolved)
      let entry._type = 'linkd'
      let entry.resolved = fnamemodify(resolved, ':p:h')
    elseif filereadable(resolved)
      let entry._type = 'linkf'
      let entry.resolved = resolved
    else
      let entry._type = 'broken'
    endif
  else
    let entry._type = a:finfo.type
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


function! s:Entry.isFile() abort
  return self._type ==# 'file'
endfunction


function! s:Entry.meansFile() abort
  return self._type ==# 'file'
    \ || self._type ==# 'linkf'
endfunction


function! s:Entry.isDirectory() abort
  return self._type ==# 'dir'
endfunction


function! s:Entry.meansDirectory() abort
  return self._type ==# 'dir'
    \ || self._type ==# 'linkd'
endfunction


function! s:Entry.isLink() abort
  return self._type ==# 'linkf'
    \ || self._type ==# 'linkd'
    \ || self._type ==# 'broken'
endfunction


function! s:Entry.isLinkToFile() abort
  return self._type ==# 'linkf'
endfunction


function! s:Entry.isLinkToDir() abort
  return self._type ==# 'linkd'
endfunction


function! s:Entry.isBrokenLink() abort
  return self._type ==# 'broken'
endfunction


function! s:Entry.getNameWithSuffix() abort
  let suffix = self.meansDirectory() ? '/' : ''
  return self.name . suffix
endfunction


let &cpoptions = s:save_cpo
