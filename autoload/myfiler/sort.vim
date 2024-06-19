let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:reverse(comparator) abort
  return { entry1, entry2 -> a:comparator(entry1, entry2) * -1 }
endfunction


let s:compare_dir_first = { entry1, entry2 ->
   \   (entry2.type ==# 'dir' || entry2.type ==# 'linkd')
   \ - (entry1.type ==# 'dir' || entry1.type ==# 'linkd')}


let s:compare_dir_last = s:reverse(s:compare_dir_first)


let s:compare_bookmark_first = { entry1, entry2 ->
    \ entry2.is_bookmarked - entry1.is_bookmarked }


let s:compare_bookmark_last = s:reverse(s:compare_bookmark_first)


let s:compare_time_asc = { entry1, entry2 -> entry1.time - entry2.time }


let s:compare_time_desc = s:reverse(s:compare_time_asc)


let s:compare_size_asc = { entry1, entry2 -> entry1.size - entry2.size }


let s:compare_size_desc = s:reverse(s:compare_size_asc)


let s:compare_name_asc = { entry1, entry2 ->
   \ entry1.name < entry2.name ? -1 :
   \ entry1.name > entry2.name ? 1 : 0 }


let s:compare_name_desc = s:reverse(s:compare_name_asc)


let s:comparator_dict = #{
    \  d: s:compare_dir_first,
    \  D: s:compare_dir_last,
    \  b: s:compare_bookmark_first,
    \  B: s:compare_bookmark_last,
    \  t: s:compare_time_asc,
    \  T: s:compare_time_desc,
    \  s: s:compare_size_asc,
    \  S: s:compare_size_desc,
    \  n: s:compare_name_asc,
    \  N: s:compare_name_desc
    \}


function! s:compose(comparator1, comparator2) abort
  return function('s:_compose', [a:comparator1, a:comparator2])
endfunction


function! s:_compose(cmp1, cmp2, e1, e2) abort
  let ret = a:cmp1(a:e1, a:e2)
  if ret != 0
    return ret
  endif
  return a:cmp2(a:e1, a:e2)
endfunction


function! myfiler#sort#init() abort
  let path = fnamemodify(myfiler#get_dir(), ':p:h')
  let b:myfiler_sort_keys =
      \ get(g:myfiler_default_sort, path, ['b', 'd', 'n'])
endfunction


function! myfiler#sort#get_comparator() abort
  let keys = filter(copy(b:myfiler_sort_keys),
      \ { _, c -> has_key(s:comparator_dict, c) })
  if empty(keys)
    return { e1, e2 -> 0 }
  endif
  let comparators = map(keys, { _, key -> s:comparator_dict[key] })
  return reduce(comparators,
      \ { composed, comparator -> s:compose(composed, comparator) })
endfunction


function! myfiler#sort#add_key(added) abort
  call filter(b:myfiler_sort_keys, { _, key -> key != a:added })
  call insert(b:myfiler_sort_keys, a:added, 0)
  call myfiler#buffer#render()
endfunction


function! myfiler#sort#delete_key(deleted) abort
  call filter(b:myfiler_sort_keys, { _, key -> key != a:deleted })
  call myfiler#buffer#render()
endfunction


let &cpoptions = s:save_cpo
