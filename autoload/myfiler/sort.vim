let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:reverse(comparator) abort
  return { entry1, entry2 -> a:comparator(entry1, entry2) * -1 }
endfunction


let s:compare_dir_first = { entry1, entry2 ->
   \   (entry2.type ==# 'dir' || entry2.type ==# 'linkd')
   \ - (entry1.type ==# 'dir' || entry1.type ==# 'linkd')}


let s:compare_dir_last = s:reverse(s:compare_dir_first)


let s:compare_name_asc = { entry1, entry2 ->
   \   entry1.name < entry2.name ? -1
   \ : entry1.name > entry2.name ? 1 : 0 }


let s:compare_name_desc = s:reverse(s:compare_name_asc)


let s:compare_time_asc = { entry1, entry2 -> entry1.time - entry2.time }


let s:compare_time_desc = s:reverse(s:compare_time_asc)


function! s:composite(comparator1, comparator2) abort
  return function('s:_composite', [a:comparator1, a:comparator2])
endfunction

function! s:_composite(cmp1, cmp2, e1, e2) abort
  let ret = a:cmp1(a:e1, a:e2)
  if ret != 0
    return ret
  endif
  return a:cmp2(a:e1, a:e2)
endfunction


function! myfiler#sort#get_comparator() abort
  if get(b:, 'myfiler_sorts_by_time')
    return s:compare_time_desc
  else
    return s:composite(
        \ s:compare_dir_first,
        \ s:compare_name_asc)
  endif
endfunction


let &cpoptions = s:save_cpo
