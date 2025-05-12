let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#view#init() abort
  call myfiler#view_item#init()
  call myfiler#filter#init()
  call myfiler#sort#init()
  let b:myfiler_entries = []
endfunction


function! myfiler#view#render() abort
  setlocal noreadonly modifiable
  call s:render()
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
      \ { _, entry -> myfiler#view_item#create_line(entry, max_namelen) })
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


let &cpoptions = s:save_cpo
