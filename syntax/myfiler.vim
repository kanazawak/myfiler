if exists('b:current_syntax')
  finish
endif

syntax match myfilerItem '.\+'     nextgroup=myfilerTime contains=myfilerDir,myfilerLink
syntax match myfilerSize '.\{7\}'  nextgroup=myfilerItem
syntax match myfilerTime '^.\{8\}\( \d\d:\d\d\)\?' nextgroup=myfilerSize
syntax match myfilerDir  '.\+/$' contained contains=myfilerLink
syntax match myfilerLink '/=>' contained

highlight! default link myfilerTime Number
highlight! default link myfilerSize Comment
highlight! default link myfilerDir Directory
highlight! default link myfilerLink Special

let b:current_syntax = 'myfiler'
