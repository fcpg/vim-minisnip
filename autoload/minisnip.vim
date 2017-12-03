" Minisnip autoload functions
let s:save_cpo = &cpo
set cpo&vim

"----------------
" Functions {{{1
"----------------

" minisnip#ExprMap() {{{2
" To be called from 'map <expr>'
function! minisnip#ExprMap(type) abort
  let l:pfx = a:type=='i' ? "x\<bs>" : ""
  let l:untriggered = g:minisnip_triggerornop
        \ ? ''
        \ : eval('"' . escape(g:minisnip_trigger, '\"<') . '"')
  let l:ret = minisnip#ShouldTrigger()
        \ ? pfx."\<esc>:call \minisnip#Minisnip()\<cr>"
        \ : l:untriggered
  return l:ret
endfun


" minisnip#InsertModeFunc() {{{2
" To be called from insert mode, eg. from '<C-r>='
function! minisnip#InsertModeFunc() abort
  stopinsert
  call feedkeys(":call minisnip#Minisnip()\<cr>")
endfun


" minisnip#TryExpand() {{{2
" Expand a snippet if possible
function! minisnip#TryExpand(cword) abort
  " look for a snippet by that name
  for l:dir in split(g:minisnip_dir, ':')
    let l:snippetfile = l:dir . '/' . a:cword
    " filetype snippets override general snippets
    for l:filetype in split(&filetype, '\.')
      let l:ft_snippetfile = l:dir . '/_' . l:filetype . '_' . a:cword
      if filereadable(l:ft_snippetfile)
        let l:snippetfile = l:ft_snippetfile
        break
      endif
    endfor
    " make sure the snippet exists
    if filereadable(l:snippetfile)
      let s:snippetfile = l:snippetfile
      return 1
    endif
  endfor
  return 0
endfun


" minisnip#ShouldJump() {{{2
" Return true if there's a placeholder to jump to
function! minisnip#ShouldJump() abort
  return search(g:minisnip_delimpat, 'en')
endfun


" minisnip#ShouldTrigger() {{{2
" Return true if a snippet was expanded or if there's a placeholder left
function! minisnip#ShouldTrigger() abort
  unlet! s:snippetfile
  let l:cword = matchstr(getline('.'), '\v\f+%' . col('.') . 'c')
  return minisnip#TryExpand(l:cword) || minisnip#ShouldJump()
endfun


" minisnip#Minisnip() {{{2
" Main function, clean up inserted text and take care of current placeholder
function! minisnip#Minisnip() abort
  if exists("s:snippetfile")
    " reset placeholder text history (for backrefs)
    let s:placeholder_texts = []
    let s:placeholder_text = ''
    " remove the snippet name
    normal! "_diw
    " adjust the indentation, use the current line as reference
    let ws = matchstr(getline(line('.')), '^\s\+')
    let lns = map(readfile(s:snippetfile), 'empty(v:val)? v:val : ws.v:val')
    " insert the snippet
    call append(line('.'), lns)
    " remove the empty line before the snippet
    normal! J
    " select the first placeholder
    call s:SelectPlaceholder()
  else
    " save the current placeholder's text so we can backref it
    let l:old_s = @s
    let l:old_mark = getpos("'s")
    " echom 'curpos:' getline('.')[col('.')-1]
    " echom 'startvisual pos:' getline('.')[col("'<")-1]
    normal! ms"syv`<`s
    call setpos("'s", l:old_mark)
    let s:placeholder_text = @s
    " echom "placeholder_text:" s:placeholder_text
    let @s = l:old_s
    " jump to the next placeholder
    call s:SelectPlaceholder()
  endif
endfun


" s:SelectPlaceholder() {{{2
" Select next placeholder
function! s:SelectPlaceholder() abort
  let l:old_s = @s

  " get the contents of the placeholder
  " we use /e here in case the cursor is already on it (which occurs ex.
  "   when a snippet begins with a placeholder)
  " we also use keeppatterns to avoid clobbering the search history /
  "   highlighting all the other placeholders
  try
    " gn misbehaves when 'wrapscan' isn't set (see vim's #1683)
    let [l:ws, &ws] = [&ws, 1]
    let l:exestr = 'normal! /' . g:minisnip_delimpat . "/e\<cr>gn\"sy"
    if exists(':keeppatterns') == 2
      silent keeppatterns execute l:exestr
    else
      silent execute l:exestr
    endif
  catch /E486:/
    " There's no placeholder at all, enter insert mode
    call feedkeys('i', 'n')
    return
  finally
    let &ws = l:ws
  endtry

  " save the contents of the previous placeholder (for backrefs)
  call add(s:placeholder_texts, s:placeholder_text)

  " save length of entire placeholder for reference later
  let l:slen = len(@s)

  " remove the start and end delimiters
  let @s = substitute(@s, '\V' . g:minisnip_startdelim, '', '')
  let @s = substitute(@s, '\V' . g:minisnip_enddelim, '', '')

  " is this placeholder marked as 'evaluate'?
  if @s =~ '\V\^' . g:minisnip_evalmarker
    " remove the marker
    let @s = substitute(@s, '\V\^' . g:minisnip_evalmarker, '', '')
    " substitute in any backrefs
    let @s = substitute(@s, '\V' . g:minisnip_backrefmarker . '\(\d\)',
          \"\\=\"'\" . substitute(get(
          \    s:placeholder_texts,
          \    len(s:placeholder_texts) - str2nr(submatch(1)), ''
          \), \"'\", \"''\", 'g') . \"'\"", 'g')
    " evaluate what's left
    let @s = eval(@s)
  endif

  if empty(@s)
    " the placeholder was empty, so just enter insert mode directly
    normal! gvd
    call feedkeys(col("'>") - l:slen >= col('$') - 1 ? 'a' : 'i', 'n')
  else
    " paste the placeholder's default value in and enter select mode on it
    execute "normal! gv\"spgv\<C-g>"
  endif

  let @s = l:old_s
endfun


let &cpo = s:save_cpo

" vim: et sw=2 ts=2 ft=vim:
