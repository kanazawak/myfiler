let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#util#echoerr(...) abort
  echohl Error
  echo call('printf', a:000)
  echohl None
endfunction


let &cpoptions = s:save_cpo
