" autolink.vim: find and insert URLs for links in Markdown and ReST

function! AutoLinkDefaultBindings()
    nnoremap <Leader>ac :call autolink#DefComplete()<CR>
    nnoremap <Leader>am :call autolink#DefCreate()<CR>
    nnoremap <Leader>al :call autolink#Combined()<CR>
endfunction
augroup AutoLink
    autocmd!
    autocmd FileType markdown,rst :call AutoLinkDefaultBindings()
augroup END
