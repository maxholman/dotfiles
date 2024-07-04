syntax on
filetype plugin on

set nofoldenable

function! ResCur()	" Restore session with cursor in last position inside line
  if line("'\"") > 1 && line("'\"") <= line('$')
    normal! g`"
    return 1
  endif
endfunction

if has('folding')
  function! UnfoldCur()
    if !&foldenable
      return
    endif
    let cl = line('.')
    if cl <= 1
      return
    endif
    let cf  = foldlevel(cl)
    let uf  = foldlevel(cl - 1)
    let min = (cf > uf ? uf : cf)
    if min
      execute 'normal!' min . 'zo'
      return 1
    endif
  endfunction
endif

augroup resCur
  autocmd!
  if has('folding')
    autocmd BufWinEnter * if ResCur() | call UnfoldCur() | endif
  else
    autocmd BufWinEnter * call ResCur()
  endif
augroup END
