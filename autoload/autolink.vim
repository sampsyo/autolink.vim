" autolink.vim: find and insert URLs for links in Markdown and ReST


" Python support functionality.
python << ENDPYTHON
import re
import sys
import urllib2
import vim

_api = None
def get_link(terms):
    query = 'https://duckduckgo.com/html/?q={}'.format(terms.strip().replace(' ','+'))
    html = urllib2.urlopen(query).read()
    for link in re.findall('div.*?web-result.*?href="(.*?)"', html, re.DOTALL):
        if "duckduckgo.com" not in link:
            return link
ENDPYTHON


" Get a DuckDuckGo result URL.
function! s:link_for_terms(terms)
python << ENDPYTHON
terms = vim.eval("a:terms")
link = get_link(terms)
vim.command("let link_out='{}'".format(link))
ENDPYTHON
    return link_out
endfunction

" Jump after the paragraph, adding a blank line if necessary (at the end of the
" file).
function! s:after_paragraph()
    execute "normal! }"
    if line('.') == line('$')
        " Last line in buffer. Make a blank line.
        execute "normal! o\<esc>"
    endif
endfunction

" Make a blank line after the current one if the next line exists and does not
" match a regex (i.e., another link definition).
function! s:blank_line_if_next_does_not_match(pat)
    if line('.') != line('$')
        let nextline = getline(line('.')+1)
        if match(nextline, a:pat) == -1
            execute "normal! o\<esc>k$"
        endif
    endif
endfunction


" Markdown

" Insert a search result URL for an existing Markdown link definition.
function! s:markdown_complete()
    execute "normal! ^l\"myt]f]c$]: \<esc>"
    let url = s:link_for_terms(@m)
    execute "normal! a".url."\<esc>"
endfunction

" Add a definition for a nearby link after the current paragraph.
function! s:markdown_create()
    " Find a Markdown reference link: [foo][bar]
    call search('\[\_[^\]]*\]\[\_[^\]]*\]', 'bc')

    " Try to get the explicit link reference key.
    execute "normal! /]\<CR>l\"myi]"
    let key = @m

    " If the key is empty, then the key is the link text itself.
    if key == ""
        execute "normal! ?[\<CR>?[\<CR>\"myi]"
        let key = @m
    endif

    " Remove newlines from the key.
    let key = substitute(key, '\n', ' ', 'g')

    " Insert the link definition after the current paragraph.
    call s:after_paragraph()
    execute "normal! o[".key."]: \<esc>"
    call s:blank_line_if_next_does_not_match('\v^\s*\[')
endfunction


" ReST

" Insert a search result for a ReST link definition.
function! s:rest_complete()
    execute "normal! ^f_l\"myt:f:c$: \<esc>"
    let url = s:link_for_terms(@m)
    execute "normal! a".url."\<esc>"
endfunction

" Insert a link definition like .. _foo:
function! s:rest_create()
    " Find a link: `foo`_
    call search('\v`\_[^`]+`', 'bc')
    " TODO: ensure the text doesn't contain <>, indicating an inline link.

    " Get the text of the link.
    execute "normal! \"myi`"
    let key = @m
    let key = substitute(key, '\n', ' ', 'g')

    " Insert the link definition after the current paragraph.
    call s:after_paragraph()
    execute "normal! o.. _".key.": \<esc>"
    call s:blank_line_if_next_does_not_match('\v^\s*\.\.')
endfunction


" Snooping URLs from browser tabs.

function! s:applescript_url_for_browser(browser)
    if a:browser == "safari"
        let app = "Safari"
        let script = 'return URL of current tab of window 1'
    elseif a:browser == "chrome"
        let app = "Google Chrome"
        let script = 'return URL of active tab of window 1'
    endif

    " Check whether the process is running.
    let pcount = system("osascript -e " . shellescape(
        \ 'tell application "System Events" to count ' .
        \ '(every process whose name is "' . app . '")'))
    if pcount[0] == '0'
        return 0
    endif

    " Run the AppleScript.
    let script = 'tell application "' . app . '" to ' . script
    let res = system("osascript -e " . shellescape(script))
    let res = substitute(res, '\n$', '', '')
    return res
endfunction

function! s:applescript_url_any()
    " Ensure we're running on OS X.
    call system("which osascript")
    if v:shell_error != 0
        echo 'this only works on OS X'
        return 0
    endif

    " Try Safari and then Chrome.
    let url = s:applescript_url_for_browser("safari")
    if url != '0'
        return url
    endif
    let url = s:applescript_url_for_browser("chrome")
    if url != '0'
        return url
    endif
    return 0
endfunction


" Main entry functions and default bindings.

function! autolink#DefComplete()
    if (&filetype == "markdown" || &filetype == "mkd")
        call s:markdown_complete()
    elseif &filetype == "rst"
        call s:rest_complete()
    endif
endfunction
function! autolink#DefCreate()
    if (&filetype == "markdown" || &filetype == "mkd")
        call s:markdown_create()
    elseif &filetype == "rst"
        call s:rest_create()
    endif
endfunction
function! autolink#Combined()
    execute "normal! mq"
    call autolink#DefCreate()
    call autolink#DefComplete()
    execute "normal! `q"
endfunction
function! autolink#AppendBrowserURL()
    let url = s:applescript_url_any()
    if url != '0'
        execute "normal! a" . url
    endif
endfunction
function! autolink#CombinedBrowser()
    execute "normal! mq"
    call autolink#DefCreate()
    call autolink#AppendBrowserURL()
    execute "normal! `q"
endfunction
