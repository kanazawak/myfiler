let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#util#echoerr(message) abort
  echohl Error
  echo a:message
  echohl None
endfunction


let &cpoptions = s:save_cpo
