let s:save_cpo = &cpoptions
set cpoptions&vim


" if exists('g:loaded_myfiler')
"   finish
" endif
let g:loaded_myfiler = 1


let g:myfiler_open_command = get(g:, 'myfiler_open_command', {})
let g:myfiler_default_view = get(g:, 'myfiler_default_view', {})
let g:myfiler_default_sort = get(g:, 'myfiler_default_sort', {})


augroup myfiler
  autocmd!
  autocmd FileType myfiler call s:setup_mappings()
  autocmd BufEnter * call s:on_bufenter()
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
  nmap <silent><buffer><nowait> .     <Plug>(myfiler-toggle-hidden-filter)
  nmap <silent><buffer><nowait> C     <Plug>(myfiler-change-directory)
  nmap <silent><buffer><nowait> *     <Plug>(myfiler-add-bookmark)

  nmap <buffer> + <Nop>
  nmap <buffer> - <Nop>
  nmap <silent><buffer><nowait> +t <Plug>(myfiler-show-date)
  nmap <silent><buffer><nowait> -t <Plug>(myfiler-hide-date)
  nmap <silent><buffer><nowait> +T <Plug>(myfiler-show-datetime)
  nmap <silent><buffer><nowait> -T <Plug>(myfiler-hide-datetime)
  nmap <silent><buffer><nowait> +s <Plug>(myfiler-show-size)
  nmap <silent><buffer><nowait> -s <Plug>(myfiler-hide-size)
  nmap <silent><buffer><nowait> +b <Plug>(myfiler-show-bookmark)
  nmap <silent><buffer><nowait> -b <Plug>(myfiler-hide-bookmark)
  nmap <silent><buffer><nowait> +D <Plug>(myfiler-show-last-slash)
  nmap <silent><buffer><nowait> -D <Plug>(myfiler-hide-last-slash)
  nmap <silent><buffer><nowait> +l <Plug>(myfiler-show-link)
  nmap <silent><buffer><nowait> -l <Plug>(myfiler-hide-link)
  nmap <silent><buffer><nowait> +a <Plug>(myfiler-show-all)
  nmap <silent><buffer><nowait> -a <Plug>(myfiler-hide-all)
  nmap <silent><buffer><nowait> +A <Plug>(myfiler-align-arrow)
  nmap <silent><buffer><nowait> -A <Plug>(myfiler-unalign-arrow)

  nmap <silent><buffer><nowait> <b <Plug>(myfiler-sort-bookmark-first)
  nmap <silent><buffer><nowait> >b <Plug>(myfiler-sort-bookmark-last)
  nmap <silent><buffer><nowait> =b <Plug>(myfiler-ignore-bookmark-on-sort)
  nmap <silent><buffer><nowait> <d <Plug>(myfiler-sort-directory-first)
  nmap <silent><buffer><nowait> >d <Plug>(myfiler-sort-directory-last)
  nmap <silent><buffer><nowait> =d <Plug>(myfiler-ignore-directory-on-sort)
  nmap <silent><buffer><nowait> <t <Plug>(myfiler-sort-by-time-asc)
  nmap <silent><buffer><nowait> >t <Plug>(myfiler-sort-by-time-desc)
  nmap <silent><buffer><nowait> =t <Plug>(myfiler-ignore-time-on-sort)
  nmap <silent><buffer><nowait> <s <Plug>(myfiler-sort-by-size-asc)
  nmap <silent><buffer><nowait> >s <Plug>(myfiler-sort-by-size-desc)
  nmap <silent><buffer><nowait> =s <Plug>(myfiler-ignore-size-on-sort)
  nmap <silent><buffer><nowait> <n <Plug>(myfiler-sort-by-name-asc)
  nmap <silent><buffer><nowait> >n <Plug>(myfiler-sort-by-name-desc)
  nmap <silent><buffer><nowait> =n <Plug>(myfiler-ignore-name-on-sort)
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
nnoremap <silent> <Plug>(myfiler-change-directory)  :<C-u>call myfiler#change_directory()<CR>
nnoremap <silent> <Plug>(myfiler-add-bookmark)      :<C-u>call myfiler#add_bookmark()<CR>

nnoremap <silent> <Plug>(myfiler-show-date)          :<C-u>call myfiler#change_view('+t')<CR>
nnoremap <silent> <Plug>(myfiler-hide-date)          :<C-u>call myfiler#change_view('-t')<CR>

nnoremap <silent> <Plug>(myfiler-show-datetime)      :<C-u>call myfiler#change_view('+T')<CR>
nnoremap <silent> <Plug>(myfiler-hide-datetime)      :<C-u>call myfiler#change_view('-T')<CR>

nnoremap <silent> <Plug>(myfiler-show-size)          :<C-u>call myfiler#change_view('+s')<CR>
nnoremap <silent> <Plug>(myfiler-hide-size)          :<C-u>call myfiler#change_view('-s')<CR>

nnoremap <silent> <Plug>(myfiler-show-bookmark)      :<C-u>call myfiler#change_view('+b')<CR>
nnoremap <silent> <Plug>(myfiler-hide-bookmark)      :<C-u>call myfiler#change_view('-b')<CR>

nnoremap <silent> <Plug>(myfiler-show-last-slash)    :<C-u>call myfiler#change_view('+D')<CR>
nnoremap <silent> <Plug>(myfiler-hide-last-slash)    :<C-u>call myfiler#change_view('-D')<CR>

nnoremap <silent> <Plug>(myfiler-show-link)          :<C-u>call myfiler#change_view('+l')<CR>
nnoremap <silent> <Plug>(myfiler-hide-link)          :<C-u>call myfiler#change_view('-l')<CR>

nnoremap <silent> <Plug>(myfiler-show-all)           :<C-u>call myfiler#show_all()<CR>
nnoremap <silent> <Plug>(myfiler-hide-all)           :<C-u>call myfiler#hide_all()<CR>

nnoremap <silent> <Plug>(myfiler-align-arrow)        :<C-u>call myfiler#change_view('+A')<CR>
nnoremap <silent> <Plug>(myfiler-unalign-arrow)      :<C-u>call myfiler#change_view('-A')<CR>

nnoremap <silent> <Plug>(myfiler-toggle-hidden-filter) :<C-u>call myfiler#toggle_hidden_filter()<CR>

nnoremap <silent> <Plug>(myfiler-sort-bookmark-first)      :<C-u>call myfiler#sort#add_key('b')<CR>
nnoremap <silent> <Plug>(myfiler-sort-bookmark-last)       :<C-u>call myfiler#sort#add_key('B')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-bookmark-on-sort)  :<C-u>call myfiler#sort#delete_key('b')<CR>
nnoremap <silent> <Plug>(myfiler-sort-directory-first)     :<C-u>call myfiler#sort#add_key('d')<CR>
nnoremap <silent> <Plug>(myfiler-sort-directory-last)      :<C-u>call myfiler#sort#add_key('D')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-directory-on-sort) :<C-u>call myfiler#sort#delete_key('d')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-time-asc)         :<C-u>call myfiler#sort#add_key('t')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-time-desc)        :<C-u>call myfiler#sort#add_key('T')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-time-on-sort)      :<C-u>call myfiler#sort#delete_key('t')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-size-asc)         :<C-u>call myfiler#sort#add_key('s')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-size-desc)        :<C-u>call myfiler#sort#add_key('S')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-size-on-sort)      :<C-u>call myfiler#sort#delete_key('s')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-name-asc)         :<C-u>call myfiler#sort#add_key('n')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-name-desc)        :<C-u>call myfiler#sort#add_key('N')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-name-on-sort)      :<C-u>call myfiler#sort#delete_key('n')<CR>


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


function! s:on_tableave() abort
  call myfiler#selection#clear()
endfunction


sign define MyFilerSelected text=>>


let &cpoptions = s:save_cpo
