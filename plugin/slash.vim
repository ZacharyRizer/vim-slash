" Copyright (c) 2016 Junegunn Choi

function! s:escape(backward)
  let command = '\V'.substitute(escape(@", '\' . (a:backward ? '?' : '/')), "\n", '\\n', 'g')
  if exists('s:save_reg')
    let @" = s:save_reg
    unlet! s:save_reg
  endif
  return command
endfunction

function! s:immobile(seq)
  let s:winline = winline()
  let s:pos = getpos('.')
  return a:seq."\<plug>(slash-prev)"
endfunction

function! s:prev()
  return getpos('.') == s:pos ? '' : '``'
endfunction

function! s:trailer()
  augroup slash
    autocmd!
    autocmd CursorMoved,CursorMovedI * let @/ = '' | autocmd! slash
  augroup END

  let s:save_search = @/

  let seq = foldclosed('.') != -1 ? 'zv' : ''
  if exists('s:winline')
    let sdiff = winline() - s:winline
    unlet s:winline
    if sdiff > 0
      let seq .= sdiff."\<c-e>"
    elseif sdiff < 0
      let seq .= -sdiff."\<c-y>"
    endif
  endif
  let after = len(maparg("<plug>(slash-after)", mode())) ? "\<plug>(slash-after)" : ''
  return seq . after
endfunction

function! s:trailer_on_leave()
  augroup slash
    autocmd!
    autocmd InsertLeave * call <sid>trailer()
  augroup END
  return ''
endfunction

function! s:wrap(seq)
  if mode() == 'c' && stridx('/?', getcmdtype()) < 0
    return a:seq
  endif
  silent! autocmd! slash
  if exists('s:save_search')
    let @/ = s:save_search
  endif
  let s:save_reg = @"
  return a:seq."\<plug>(slash-trailer)"
endfunction

map      <expr> <plug>(slash-trailer) <sid>trailer()
imap     <expr> <plug>(slash-trailer) <sid>trailer_on_leave()
cnoremap        <plug>(slash-cr)      <cr>
noremap  <expr> <plug>(slash-prev)    <sid>prev()
inoremap        <plug>(slash-prev)    <nop>
noremap!        <plug>(slash-nop)     <nop>

cmap <expr> <cr> <sid>wrap("\<cr>")
map  <expr> n    <sid>wrap('n')
map  <expr> N    <sid>wrap('N')
map  <expr> *    <sid>wrap(<sid>immobile('*'))
map  <expr> #    <sid>wrap(<sid>immobile('#'))
map  <expr> g*   <sid>wrap(<sid>immobile('g*'))
map  <expr> g#   <sid>wrap(<sid>immobile('g#'))
xmap <expr> *    <sid>wrap(<sid>immobile("y/\<c-r>=<sid>escape(0)\<plug>(slash-cr)\<plug>(slash-cr)"))
xmap <expr> #    <sid>wrap(<sid>immobile("y?\<c-r>=<sid>escape(1)\<plug>(slash-cr)\<plug>(slash-cr)"))
