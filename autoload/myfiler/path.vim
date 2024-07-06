let s:save_cpo = &cpoptions
set cpoptions&vim


" Prototype-based OOP
let s:Path = {}


function! myfiler#path#new(pathStr) abort
  let pathObj = deepcopy(s:Path)
  let pathObj._path = a:pathStr
  return pathObj
endfunction


function! s:Path.ToString() abort
  return self._path
endfunction


function! s:Path.IsReadble() abort
  return filereadable(self._path) || isdirectory(self._path)
endfunction


function! s:Path.Append(basename) abort
  let pathStr = fnamemodify(self._path, ':p') . a:basename
  return myfiler#path#new(pathStr)
endfunction


function! s:Path.Resolve() abort
  let resolved = fnamemodify(resolve(self._path), ':p')
  if isdirectory(resolved)
    let resolved = fnamemodify(resolved, ':h')
  endif
  return myfiler#path#new(resolved)
endfunction


function! s:Path.IsRoot() abort
  return fnamemodify(self._path, ':h') ==# self._path
endfunction


function! s:Path.GetParent() abort
  let pathStr = fnamemodify(self._path, ':h')
  return myfiler#path#new(pathStr)
endfunction


function! s:Path.Exists() abort
  return !empty(glob(self._path, 1, 1))
endfunction


function! s:Path.GetBasename() abort
  return fnamemodify(self._path, ':t')
endfunction


function! s:Path.GetFileExt() abort
  return fnamemodify(self._path, ':e')
endfunction


let &cpoptions = s:save_cpo
