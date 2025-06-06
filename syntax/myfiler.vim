if exists('b:current_syntax')
  finish
endif

syntax match myfilerItem '^.\+$\|.\+$' nextgroup=myfilerTime contains=myfilerDir,myfilerFile,myfilerLinkToFile,myfilerLinkToDir
syntax match myfilerBookmark '[ *]' nextgroup=myfilerItem
syntax match myfilerSize '[ 0-9.]\{3\}[BKMGTP ] ' nextgroup=myfilerBookmark
syntax match myfilerTime '^\d\d/\d\d/\d\d\( \d\d:\d\d\)\? ' nextgroup=myfilerSize

syntax match myfilerFile '[^/]*[^/]$' contained contains=myfilerExt
syntax match myfilerDir  '[^/]\+/$' contained
syntax match myfilerLinkToFile '[^/]\+\t/=> .*[^/]$' contained contains=myfilerName,myfilerArrow,myfilerResolvedFile
syntax match myfilerLinkToDir  '[^/]\+\t/=> .\+/$' contained contains=myfilerName,myfilerArrow,myfilerResolvedDir

syntax match myfilerResolvedFile '.*$' contained contains=myfilerExt
syntax match myfilerResolvedDir  '.*$' contained
syntax match myfilerArrow '\t/=> ' contained
syntax match myfilerName '[^/]*[^/ ]\ze\t/' contained
syntax match myfilerExt '[^ /]\.\zs[^./]\+$' contained

highlight! default link myfilerTime        Number
highlight! default link myfilerSize        Comment
highlight! default link myfilerBookmark    Tag
highlight! default link myfilerDir         Directory
highlight! default link myfilerResolvedDir Directory
highlight! default link myfilerName        Underlined
highlight! default link myfilerArrow       Comment
highlight! default link myfilerExt         Type

let b:current_syntax = 'myfiler'
