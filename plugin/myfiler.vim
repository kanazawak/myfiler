let s:save_cpo = &cpoptions
set cpoptions&vim


" if exists('g:loaded_myfiler')
"   finish
" endif
let g:loaded_myfiler = 1


let g:myfiler_open_command = get(g:, 'myfiler_open_command', {})
let g:myfiler_default_view = get(g:, 'myfiler_default_view', {})
let g:myfiler_default_sort = get(g:, 'myfiler_default_sort', {})
let g:myfiler_default_visibility = get(g:, 'myfiler_default_visibility', {})


augroup myfiler
  autocmd!
  autocmd FileType myfiler call s:setup_mappings()
  autocmd BufEnter * call s:on_bufenter()
  autocmd TabLeave * call s:on_tableave()
augroup END


function! s:setup_mappings() abort
  nmap <silent><buffer><nowait> l    <Plug>(myfiler-open-dir)
  nmap <silent><buffer><nowait> h    <Plug>(myfiler-open-parent)
  nmap <silent><buffer><nowait> <CR> <Plug>(myfiler-open-current)
  nmap <silent><buffer><nowait> ~    <Plug>(myfiler-open-home)
  nmap <silent><buffer><nowait> C    <Plug>(myfiler-change-directory)
  nmap <silent><buffer><nowait> R    <Plug>(myfiler-reload)
  nmap <silent><buffer><nowait> s    <Plug>(myfiler-select-forward)
  nmap <silent><buffer><nowait> S    <Plug>(myfiler-select-backward)
  nmap <silent><buffer><nowait> x    <Plug>(myfiler-execute)

  nmap <silent><buffer><nowait> o    <Plug>(myfiler-new-file)
  nmap <silent><buffer><nowait> O    <Plug>(myfiler-new-dir)
  nmap <silent><buffer><nowait> r    <Plug>(myfiler-rename)
  nmap <silent><buffer><nowait> m    <Plug>(myfiler-move)
  nmap <silent><buffer><nowait> d    <Plug>(myfiler-delete)
  nmap <silent><buffer><nowait> p    <Plug>(myfiler-copy)
  nmap <silent><buffer><nowait> *    <Plug>(myfiler-add-bookmark)

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

  nmap <silent><buffer><nowait> .  <Plug>(myfiler-toggle-hidden-filter)
  nmap <silent><buffer><nowait> f/ <Plug>(myfiler-add-pattern-filter)
  nmap <silent><buffer><nowait> F/ <Plug>(myfiler-clear-pattern-filters)
endfunction


nnoremap <silent> <Plug>(myfiler-open-current)     <Cmd>call myfiler#open_current()<CR>
nnoremap <silent> <Plug>(myfiler-open-dir)         <Cmd>call myfiler#open_dir()<CR>
nnoremap <silent> <Plug>(myfiler-open-parent)      <Cmd>call myfiler#open_parent()<CR>
nnoremap <silent> <Plug>(myfiler-open-home)        <Cmd>call myfiler#open(expand("~"))<CR>
nnoremap <silent> <Plug>(myfiler-change-directory) <Cmd>call myfiler#change_directory()<CR>
nnoremap <silent> <Plug>(myfiler-reload)           <Cmd>call myfiler#reload()<CR>
nnoremap <silent> <Plug>(myfiler-select-forward)   <Cmd>call myfiler#toggle_selection(v:true)<CR>
nnoremap <silent> <Plug>(myfiler-select-backward)  <Cmd>call myfiler#toggle_selection(v:false)<CR>
nnoremap <silent> <Plug>(myfiler-execute)          <Cmd>call myfiler#execute()<CR>

nnoremap <silent> <Plug>(myfiler-new-file)     <Cmd>call myfiler#operation#new_file()<CR>
nnoremap <silent> <Plug>(myfiler-new-dir)      <Cmd>call myfiler#operation#new_dir()<CR>
nnoremap <silent> <Plug>(myfiler-rename)       <Cmd>call myfiler#operation#rename()<CR>
nnoremap <silent> <Plug>(myfiler-move)         <Cmd>call myfiler#operation#move()<CR>
nnoremap <silent> <Plug>(myfiler-delete)       <Cmd>call myfiler#operation#delete()<CR>
nnoremap <silent> <Plug>(myfiler-copy)         <Cmd>call myfiler#operation#copy()<CR>
nnoremap <silent> <Plug>(myfiler-add-bookmark) <Cmd>call myfiler#operation#add_bookmark()<CR>

nnoremap <silent> <Plug>(myfiler-show-date)       <Cmd>call myfiler#view#update_item('+t')<CR>
nnoremap <silent> <Plug>(myfiler-hide-date)       <Cmd>call myfiler#view#update_item('-t')<CR>
nnoremap <silent> <Plug>(myfiler-show-datetime)   <Cmd>call myfiler#view#update_item('+T')<CR>
nnoremap <silent> <Plug>(myfiler-hide-datetime)   <Cmd>call myfiler#view#update_item('-T')<CR>
nnoremap <silent> <Plug>(myfiler-show-size)       <Cmd>call myfiler#view#update_item('+s')<CR>
nnoremap <silent> <Plug>(myfiler-hide-size)       <Cmd>call myfiler#view#update_item('-s')<CR>
nnoremap <silent> <Plug>(myfiler-show-bookmark)   <Cmd>call myfiler#view#update_item('+b')<CR>
nnoremap <silent> <Plug>(myfiler-hide-bookmark)   <Cmd>call myfiler#view#update_item('-b')<CR>
nnoremap <silent> <Plug>(myfiler-show-last-slash) <Cmd>call myfiler#view#update_item('+D')<CR>
nnoremap <silent> <Plug>(myfiler-hide-last-slash) <Cmd>call myfiler#view#update_item('-D')<CR>
nnoremap <silent> <Plug>(myfiler-show-link)       <Cmd>call myfiler#view#update_item('+l')<CR>
nnoremap <silent> <Plug>(myfiler-hide-link)       <Cmd>call myfiler#view#update_item('-l')<CR>
nnoremap <silent> <Plug>(myfiler-align-arrow)     <Cmd>call myfiler#view#update_item('+A')<CR>
nnoremap <silent> <Plug>(myfiler-unalign-arrow)   <Cmd>call myfiler#view#update_item('-A')<CR>
nnoremap <silent> <Plug>(myfiler-show-all)        <Cmd>call myfiler#view#show_all()<CR>
nnoremap <silent> <Plug>(myfiler-hide-all)        <Cmd>call myfiler#view#hide_all()<CR>

nnoremap <silent> <Plug>(myfiler-sort-bookmark-first)      <Cmd>call myfiler#view#add_sort_key('b')<CR>
nnoremap <silent> <Plug>(myfiler-sort-bookmark-last)       <Cmd>call myfiler#view#add_sort_key('B')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-bookmark-on-sort)  <Cmd>call myfiler#view#delete_sort_key('b')<CR>
nnoremap <silent> <Plug>(myfiler-sort-directory-first)     <Cmd>call myfiler#view#add_sort_key('d')<CR>
nnoremap <silent> <Plug>(myfiler-sort-directory-last)      <Cmd>call myfiler#view#add_sort_key('D')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-directory-on-sort) <Cmd>call myfiler#view#delete_sort_key('d')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-time-asc)         <Cmd>call myfiler#view#add_sort_key('t')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-time-desc)        <Cmd>call myfiler#view#add_sort_key('T')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-time-on-sort)      <Cmd>call myfiler#view#delete_sort_key('t')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-size-asc)         <Cmd>call myfiler#view#add_sort_key('s')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-size-desc)        <Cmd>call myfiler#view#add_sort_key('S')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-size-on-sort)      <Cmd>call myfiler#view#delete_sort_key('s')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-name-asc)         <Cmd>call myfiler#view#add_sort_key('n')<CR>
nnoremap <silent> <Plug>(myfiler-sort-by-name-desc)        <Cmd>call myfiler#view#add_sort_key('N')<CR>
nnoremap <silent> <Plug>(myfiler-ignore-name-on-sort)      <Cmd>call myfiler#view#delete_sort_key('n')<CR>

nnoremap <silent> <Plug>(myfiler-toggle-hidden-filter)  <Cmd>call myfiler#view#toggle_hidden_filter()<CR>
nnoremap <silent> <Plug>(myfiler-add-pattern-filter)    <Cmd>call myfiler#view#add_pattern_filter()<CR>
nnoremap <silent> <Plug>(myfiler-clear-pattern-filters) <Cmd>call myfiler#view#clear_pattern_filters()<CR>


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
