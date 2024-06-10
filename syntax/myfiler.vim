if exists('b:current_syntax')
  finish
endif

syntax match myfilerItem '.\+'     nextgroup=myfilerTime contains=myfilerDir,myfilerFile,myfilerLinkToFile,myfilerLinkToDir
syntax match myfilerSize '.\{7\}'  nextgroup=myfilerItem
syntax match myfilerTime '^.\{8\}\( \d\d:\d\d\)\?' nextgroup=myfilerSize

syntax match myfilerFile '[^/]*[^/]$' contained contains=myfilerExt
syntax match myfilerDir  '[^/]\+/$'   contained
syntax match myfilerLinkToFile '[^/]\+ /=> .*[^/]$' contained contains=myfilerName,myfilerArrow,myfilerResolvedFile
syntax match myfilerLinkToDir  '[^/]\+ /=> .\+/$'   contained contains=myfilerName,myfilerArrow,myfilerResolvedDir

syntax match myfilerResolvedFile '.*$' contained contains=myfilerExt
syntax match myfilerResolvedDir  '.*$' contained
syntax match myfilerArrow ' /=> ' contained nextgroup=myfilerResolved
syntax match myfilerName '[^/]\+\ze /' contained nextgroup=myfilerArrow
syntax match myfilerExt '\S\.\zs[^.]\+$' contained

highlight! default link myfilerTime        Number
highlight! default link myfilerSize        Comment
highlight! default link myfilerDir         Directory
highlight! default link myfilerResolvedDir Directory
highlight! default link myfilerName        Underlined
highlight! default link myfilerArrow       Comment
highlight! default link myfilerExt         Type

let b:current_syntax = 'myfiler'
