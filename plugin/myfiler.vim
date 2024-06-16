let s:save_cpo = &cpoptions
set cpoptions&vim


" if exists('g:loaded_myfiler')
"   finish
" endif
let g:loaded_myfiler = 1


let g:myfiler_open_command = get(g:, 'myfiler_open_command', {})


augroup myfiler
  autocmd!
  autocmd FileType myfiler call s:setup_mappings()
  autocmd BufEnter * call s:on_bufenter()
  " autocmd BufLeave * call s:on_bufleave()
  autocmd WinLeave * call s:on_winleave()
  autocmd TabLeave * call s:on_tableave()
augroup END


function! s:setup_mappings() abort
  nmap <silent><buffer><nowait> l     <Plug>(myfiler-open-dir)
  nmap <silent><buffer><nowait> h     <Plug>(myfiler-open-parent)
  nmap <silent><buffer><nowait> <CR>  <Plug>(myfiler-open-current)
  nmap <silent><buffer><nowait> ~     <Plug>(myfiler-open-home)
  nmap <silent><buffer><nowait> R     <Plug>(myfiler-reload)
  nmap <silent><buffer><nowait> s     <Plug>(myfiler-select-forward)
  nmap <silent><buffer><nowait> S     <Plug>(myfiler-select-backward)
  nmap <silent><buffer><nowait> x     <Plug>(myfiler-execute)
  nmap <silent><buffer><nowait> o     <Plug>(myfiler-new-file)
  nmap <silent><buffer><nowait> O     <Plug>(myfiler-new-dir)
  nmap <silent><buffer><nowait> r     <Plug>(myfiler-rename)
  nmap <silent><buffer><nowait> m     <Plug>(myfiler-move)
  nmap <silent><buffer><nowait> d     <Plug>(myfiler-delete)
  " nmap <silent><buffer><nowait> p     <Plug>(myfiler-copy)
  nmap <silent><buffer><nowait> .     <Plug>(myfiler-change-visibility)
  nmap <silent><buffer><nowait> T     <Plug>(myfiler-change-sort)
  nmap <silent><buffer><nowait> c     <Plug>(myfiler-change-directory)
  nmap <silent><buffer><nowait> y$    <Plug>(myfiler-yank-path)
  nmap <silent><buffer><nowait> yy    <Plug>(myfiler-yank-path-with-nl)

  nmap <buffer> - <Nop>
  nmap <buffer> + <Nop>
  nmap <silent><buffer><nowait> -t    <Plug>(myfiler-shrink-time)
  nmap <silent><buffer><nowait> +t    <Plug>(myfiler-expand-time)
  nmap <silent><buffer><nowait> -T    <Plug>(myfiler-shrink-time-full)
  nmap <silent><buffer><nowait> +T    <Plug>(myfiler-expand-time-full)
  nmap <silent><buffer><nowait> -s    <Plug>(myfiler-hide-size)
  nmap <silent><buffer><nowait> +s    <Plug>(myfiler-show-size)
endfunction


nnoremap <silent> <Plug>(myfiler-open-current)      :<C-u>call myfiler#open_current()<CR>
nnoremap <silent> <Plug>(myfiler-open-dir)          :<C-u>call myfiler#open_dir()<CR>
nnoremap <silent> <Plug>(myfiler-open-parent)       :<C-u>call myfiler#open_parent()<CR>
nnoremap <silent> <Plug>(myfiler-open-home)         :<C-u>call myfiler#open(expand("~"))<CR>
nnoremap <silent> <Plug>(myfiler-reload)            :<C-u>call myfiler#reload()<CR>
nnoremap <silent> <Plug>(myfiler-select-forward)    :<C-u>call myfiler#toggle_selection(v:true)<CR>
nnoremap <silent> <Plug>(myfiler-select-backward)   :<C-u>call myfiler#toggle_selection(v:false)<CR>
nnoremap <silent> <Plug>(myfiler-execute)           :<C-u>call myfiler#execute()<CR>
nnoremap <silent> <Plug>(myfiler-new-file)          :<C-u>call myfiler#new_file()<CR>
nnoremap <silent> <Plug>(myfiler-new-dir)           :<C-u>call myfiler#new_dir()<CR>
nnoremap <silent> <Plug>(myfiler-rename)            :<C-u>call myfiler#rename()<CR>
nnoremap <silent> <Plug>(myfiler-move)              :<C-u>call myfiler#move()<CR>
nnoremap <silent> <Plug>(myfiler-delete)            :<C-u>call myfiler#delete()<CR>
" nnoremap <silent> <Plug>(myfiler-copy)              :<C-u>call myfiler#copy()<CR>
nnoremap <silent> <Plug>(myfiler-change-visibility) :<C-u>call myfiler#change_visibility()<CR>
nnoremap <silent> <Plug>(myfiler-change-sort)       :<C-u>call myfiler#change_sort()<CR>
nnoremap <silent> <Plug>(myfiler-change-directory)  :<C-u>call myfiler#change_directory()<CR>
nnoremap <silent> <Plug>(myfiler-yank-path)         :<C-u>call myfiler#yank_path(v:false)<CR>
nnoremap <silent> <Plug>(myfiler-yank-path-with-nl) :<C-u>call myfiler#yank_path(v:true)<CR>
nnoremap <silent> <Plug>(myfiler-shrink-time)       :<C-u>call myfiler#shrink_time(1)<CR>
nnoremap <silent> <Plug>(myfiler-expand-time)       :<C-u>call myfiler#expand_time(1)<CR>
nnoremap <silent> <Plug>(myfiler-shrink-time-full)  :<C-u>call myfiler#shrink_time(2)<CR>
nnoremap <silent> <Plug>(myfiler-expand-time-full)  :<C-u>call myfiler#expand_time(2)<CR>
nnoremap <silent> <Plug>(myfiler-hide-size)         :<C-u>call myfiler#hide_size()<CR>
nnoremap <silent> <Plug>(myfiler-show-size)         :<C-u>call myfiler#show_size()<CR>


function! s:on_bufenter() abort
  " Remove netrw autocmds
  autocmd! FileExplorer *

  let path = expand('%')
  if !isdirectory(path)
    return
  endif

  if &filetype != 'myfiler' || myfiler#buffer#is_empty()
    call myfiler#buffer#init()
  endif

  " Note that Vim set 'buflisted' when starting to edit a buffer
  setlocal nobuflisted
endfunction


function! s:on_winleave() abort
endfunction


function! s:on_tableave() abort
  call myfiler#selection#clear()
endfunction


sign define MyFilerSelected text=>>


let &cpoptions = s:save_cpo
