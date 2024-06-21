let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#view#init() abort
  let path = myfiler#get_dir()
  call myfiler#view_item#init(path)
  call myfiler#filter#init(path)
  call myfiler#sort#init(path)
  let b:myfiler_entries = []
endfunction


function! myfiler#view#render() abort
  setlocal noreadonly modifiable

  let selection = myfiler#selection#get()
  if selection.bufnr == bufnr()
    call myfiler#selection#clear()
  endif

  call s:render()

  if selection.bufnr == bufnr()
    call myfiler#selection#restore(selection)
  endif

  setlocal readonly nomodifiable nomodified
endfunction


function! s:render() abort
  let new_entries = copy(b:myfiler_loaded_entries)
  call filter(new_entries, myfiler#filter#get_acceptor())
  call sort(new_entries, myfiler#sort#get_comparator())

  let old_entries = b:myfiler_entries
  let b:myfiler_entries = new_entries

  let name_dict = {}
  for entry in new_entries
    let name_dict[entry.name] = v:true
  endfor
  for i in range(len(old_entries) - 1, 0, -1)
    if !get(name_dict, old_entries[i].name)
      call remove(old_entries, i)
      call deletebufline('', i + 1)
    endif
  endfor
  let cursor_name = empty(old_entries) ? '' : old_entries[line('.') - 1].name

  let max_namelen = max(map(copy(new_entries),
      \ { _, e  -> strdisplaywidth(e.name) }))

  let lines = map(copy(new_entries),
      \ { _, entry -> s:create_line(entry, max_namelen) })
  call setline(1, lines)

  call myfiler#search_name(cursor_name)
endfunction


function! myfiler#view#update_item(str) abort
  call myfiler#view_item#update(a:str)
  call myfiler#view#render()
endfunction


function! myfiler#view#show_all() abort
  call myfiler#view_item#show_all()
  call myfiler#view#render()
endfunction


function! myfiler#view#hide_all() abort
  call myfiler#view_item#hide_all()
  call myfiler#view#render()
endfunction


function! myfiler#view#add_sort_key(key) abort
  call myfiler#sort#add_key(a:key)
  call myfiler#view#render()
endfunction


function! myfiler#view#delete_sort_key(key) abort
  call myfiler#sort#delete_key(a:key)
  call myfiler#view#render()
endfunction


function! myfiler#view#toggle_hidden_filter() abort
  call myfiler#filter#toggle()
  call myfiler#view#render()
endfunction


function! myfiler#view#add_pattern_filter() abort
  if empty(b:myfiler_entries)
    return
  endif

  let saved_hls = &hlsearch
  set hlsearch
  let saved_reg = @/
  let @/ = ''
  let saved_view = myfiler#view_item#save()
  call myfiler#view_item#hide_all()
  call myfiler#view_item#update('+D')
  call myfiler#view#render()
  redraw

  augroup incremental_search
    autocmd!
    autocmd CmdlineChanged @ call s:update_searchstr()
  augroup END

  try
    call myfiler#filter#add_pattern('.')  " dummy pattern
    let pattern = input('Input pattern: ')
    call feedkeys('', 'nx')
    redraw
    if pattern ==# '' || empty(b:myfiler_entries)
      call myfiler#filter#pop_pattern()
    endif
  finally
    augroup incremental_search
      autocmd!
    augroup END

    call myfiler#view_item#restore(saved_view)
    call myfiler#view#render()
    let @/ = saved_reg
    let &hlsearch = saved_hls
  endtry
endfunction


function s:update_searchstr() abort
  let @/ = getcmdline()
  call myfiler#filter#pop_pattern()
  call myfiler#filter#add_pattern(@/)
  call myfiler#view#render()
  redraw
endfunction


function! myfiler#view#clear_pattern_filters() abort
  call myfiler#filter#clear_patterns()
  call myfiler#view#render()
endfunction


let &cpoptions = s:save_cpo
