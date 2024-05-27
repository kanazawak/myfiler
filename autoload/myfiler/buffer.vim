let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return search('.', 'n') == 0
endfunction


function! myfiler#buffer#init() abort
  mapclear <buffer>
  call myfiler#buffer#render()
  setlocal buftype=nowrite
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nowrap
  setlocal filetype=myfiler
endfunction


function! myfiler#buffer#render() abort
  let lines1 = myfiler#buffer#is_empty() ? [] : getbufline('', 1, '$')
  let names1 = map(copy(lines1), 'strpart(v:val, 22)')

  let ls = 'ls -AlhD "%y/%m/%d %H:%M" '
  let dir = myfiler#get_dir()
  let tail = 'tail +2'
  let perl = "perl -alne 'printf qq|%s %s %5s  %s\n|, @F[5..6], /^-/ && $F[4], join(q| |, @F[7..$#F])'"
  let lines2 = systemlist(ls . dir . '|' . tail . '|' . perl)
  let names2 = map(copy(lines2), 'strpart(v:val, 22)')

  setlocal modifiable
  
  " Utilize diff to not disturb cursor positions for same buffer in other windows
  if !empty(lines1)
    let hunks = diff(names1, names2, #{ output: 'indices' })
    call sort(hunks, { h1, h2 -> h2.from_idx - h1.from_idx })
    for hunk in hunks
      if hunk.from_count == 0
        call appendbufline('', hunk.from_idx, range(hunk.to_count))
      elseif hunk.to_count == 0
        call deletebufline('', hunk.from_idx + 1 , hunk.from_idx + hunk.from_count)
      endif
    endfor
  endif
  call setline(1, lines2)

  setlocal nomodifiable
  setlocal nomodified
endfunction


let &cpoptions = s:save_cpo
