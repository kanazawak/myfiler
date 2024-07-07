let s:save_cpo = &cpoptions
set cpoptions&vim


" Prototype-based OOP
let s:Entry = {}


function! myfiler#entry#new(finfo, dir, is_bookmarked) abort
  let entry = deepcopy(s:Entry)
  let entry.name = a:finfo.name
  let entry.path = a:dir.Append(a:finfo.name)
  let entry.size = a:finfo.size
  let entry.time = a:finfo.time
  let entry.isBookmarked = a:is_bookmarked

  let resolved = entry.path.Resolve()
  if !resolved.Equals(entry.path)
    if resolved.IsDirectory()
      let entry._type = 'linkd'
    elseif resolved.IsReadble()
      let entry._type = 'linkf'
    else
      let entry._type = 'broken'
    endif
  else
    " TODO: Handle unnormal files (Ex. bdev, socket)
    let entry._type = a:finfo.type
  endif

  return entry
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
