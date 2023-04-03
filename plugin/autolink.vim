" autolink.vim: find and insert URLs for links in Markdown and ReST

function! AutoLinkDefaultBindings()
    nnoremap <Leader>ac :call autolink#DefComplete()<CR>
    nnoremap <Leader>am :call autolink#DefCreate()<CR>
    nnoremap <Leader>al :call autolink#Combined()<CR>
    nnoremap <Leader>aB :call autolink#AppendBrowserURL()<CR>
    nnoremap <Leader>ab :call autolink#CombinedBrowser()<CR>
    nnoremap <Leader>as :call autolink#Search()<CR>
endfunction
augroup AutoLink
    autocmd!
    autocmd FileType markdown,wiki,rst :call AutoLinkDefaultBindings()
augroup END
