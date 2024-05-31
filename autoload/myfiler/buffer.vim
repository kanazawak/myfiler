let s:save_cpo = &cpoptions
set cpoptions&vim


function! myfiler#buffer#is_empty() abort
  return search('.', 'n') == 0
endfunction


function! myfiler#buffer#init() abort
  mapclear <buffer>
  setlocal filetype=myfiler
  let b:myfiler_shows_hidden_files = v:false
  call myfiler#buffer#render()
  setlocal buftype=nowrite
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nowrap
endfunction


let s:units = ['B', 'K', 'M', 'G', 'T', 'P']
function! s:make_fsize_readable(bytes) abort
  let x = a:bytes
  for i in range(len(s:units))
    if x < 1024
      if i == 0
        return x . s:units[0]
      elseif x < 10
        return printf("%.1f", x) . s:units[i]
      else
        return printf("%.0f", x) . s:units[i]
      endif
    endif
    let x = x / 1024.0
  endfor
endfunction


function! myfiler#buffer#delete_line(lnum) abort
  " Work around a bug? of Vim:
  "   When two windows shows same buffer and their cursors are on same line,
  "   deleting the line in one of the windows causes the other windows's cursor moves up.
  let cursor_lnum = line('.')
  if a:lnum == line('$')
    return deletebufline('', a:lnum)
  endif
  execute (a:lnum + 1) . 'move' . (a:lnum - 1)
  execute 'normal!' (a:lnum == line('$') - 1 ? 'jdd' : 'jddk')
  if cursor_lnum == line('$') + 1
    execute line('$')
  elseif a:lnum < cursor_lnum
    execute (cursor_lnum - 1)
  else
    execute cursor_lnum
  endif
endfunction


function! myfiler#buffer#render() abort
  let old_names = myfiler#buffer#is_empty() ? []
        \ : map(range(line('$')), { i -> myfiler#get_basename(i + 1) })
  let dir = myfiler#get_dir()

  let shows_hidden = get(b:, 'myfiler_shows_hidden_files', v:false)
  let entries = shows_hidden
        \ ? readdirex(dir)
        \ : readdirex(dir, { entry -> entry.name !~ '^\.' })
  let new_names = map(copy(entries), { _, entry -> entry.name })

  setlocal modifiable
  
  " Utilize diff to not disturb cursor positions (on same buffer in other windows) and signs
  if !empty(old_names)
    let hunks = diff(old_names, new_names, #{ output: 'indices' })
    call sort(hunks, { h1, h2 -> h2.from_idx - h1.from_idx })
    for hunk in hunks
      if hunk.from_count == 0
        call appendbufline('', hunk.from_idx, range(hunk.to_count))
      elseif hunk.to_count == 0
        for _ in range(hunk.from_count)
          call myfiler#buffer#delete_line(hunk.from_idx + 1)
        endfor
      endif
    endfor
  endif

  for i in range(len(entries))
    let entry = entries[i]
    " TODO: Delicate handling cf. getftype()
    let type = entry.type[0] 
    let size = type ==# 'f' ? s:make_fsize_readable(entry.size) : ''
    let datetime = strftime("%y/%m/%d %H:%M", entry.time) 
    let label = entry.name
    if type ==# 'l'
      let resolved = resolve(dir . '/' . entry.name)
      let suffix = filereadable(resolved) || isdirectory(resolved)
            \ ? ' /=> ' . resolved
            \ : ' /=> (BROKEN LINK)'
      let label = label . suffix
    endif
    call setline(i + 1, printf("%s %5s  %s", datetime, size, label))
  endfor

  setlocal nomodifiable
  setlocal nomodified
endfunction


let &cpoptions = s:save_cpo
