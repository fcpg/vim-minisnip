" minisnip - simple snippet in VimL
if exists("g:loaded_minisnip")
  finish
endif
let g:loaded_minisnip = 1

let s:save_cpo = &cpo
set cpo&vim


"--------------
" Options {{{1
"--------------

let g:minisnip_dir           = fnamemodify(get(g:, 'minisnip_dir',
                                  \ '~/.vim/minisnip'), ':p')
let g:minisnip_trigger       = get(g:, 'minisnip_trigger', '<Tab>')
let g:minisnip_startdelim    = get(g:, 'minisnip_startdelim', '{{+')
let g:minisnip_enddelim      = get(g:, 'minisnip_enddelim', '+}}')
let g:minisnip_evalmarker    = get(g:, 'minisnip_evalmarker', '~')
let g:minisnip_backrefmarker = get(g:, 'minisnip_backrefmarker', '\\~')
" 1 = no-op if not triggered, 0 = send g:minisnip_trigger
let g:minisnip_triggerornop  = get(g:, 'minisnip_triggerornop', 0)
let g:minisnip_nomaps        = get(g:, 'minisnip_nomaps', 0)

" Pattern used to find placeholders
let g:minisnip_delimpat = '\V' . g:minisnip_startdelim .
                            \ '\.\{-}' . g:minisnip_enddelim


"---------------
" Mappings {{{1
"---------------

inoremap <expr> <Plug>Minisnip  minisnip#ExprMap('i')
snoremap <expr> <Plug>Minisnip  minisnip#ExprMap('s')

" Add the default mappings if the user hasn't defined any
if !hasmapto('<Plug>Minisnip') && !g:minisnip_nomaps
  execute 'imap <unique> ' . g:minisnip_trigger . ' <Plug>Minisnip'
  execute 'smap <unique> ' . g:minisnip_trigger . ' <Plug>Minisnip'
endif


let &cpo = s:save_cpo

" vim: et sw=2 ts=2 ft=vim:
