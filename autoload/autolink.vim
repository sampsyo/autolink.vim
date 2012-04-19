" autolink.vim: find and insert URLs for links in Markdown and ReST


" Python support functionality.
python << ENDPYTHON
import vim
_api = None
def get_link(terms):
    # Lazily initialize API singleton.
    global _api
    if not _api:
        _api = Blekko(source='410a531a')
    # Perform query.
    try:
        res = _api.query(terms + ' /ps=1')
    except BlekkoError as exc:
        return None
    if len(res):
        return res[0].url
ENDPYTHON


" Get a Blekko result URL.
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


" Main entry functions and default bindings.

function! autolink#DefComplete()
    if &filetype == "markdown"
        call s:markdown_complete()
    elseif &filetype == "rst"
        call s:rest_complete()
    endif
endfunction
function! autolink#DefCreate()
    if &filetype == "markdown"
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


" The python-blekko module, inlined.

python << ENDPYTHON
"""Bindings for the Blekko search API."""
import urllib
import time
import threading
import json

BASE_URL = 'http://blekko.com'
RATE_LIMIT = 1.0  # Seconds.

class _rate_limit(object):
    """A decorator that limits the rate at which the function may be
    called. Minimum interval is given by RATE_LIMIT. Thread-safe using
    locks.
    """
    def __init__(self, fun):
        self.fun = fun
        self.last_call = 0.0
        self.lock = threading.Lock()

    def __call__(self, *args, **kwargs):
        with self.lock:
            # Wait until RATE_LIMIT time has passed since last_call,
            # then update last_call.
            since_last_call = time.time() - self.last_call
            if since_last_call < RATE_LIMIT:
                time.sleep(RATE_LIMIT - since_last_call)
            self.last_call = time.time()

            # Call the original function.
            return self.fun(*args, **kwargs)

class BlekkoError(Exception):
    """Base class for exceptions raised by this module."""

class ServerError(BlekkoError):
    """Raised when the server denies a request for some reason."""

@_rate_limit
def _http_request(url):
    """Make a (rate-limited) request to the Blekko server and return the
    resulting data.
    """
    f = urllib.urlopen(url)
    code = f.getcode()
    if code == 503:
        raise ServerError('server overloaded (503)')
    elif code != 200:
        raise ServerError('HTTP error {}'.format(code))
    return f.read()

class ResponseObject(object):
    """An object wrapper for a dictionary providing item access to
    values in the underlying dictionary.
    """
    def __init__(self, data):
        self.data = data

    def __getattr__(self, key):
        if key in self.data:
            return self.data[key]
        raise KeyError('no such field {}'.format(repr(key)))

    def __repr__(self):
        return '{}({})'.format(type(self).__name__, self.data)

class Result(ResponseObject):
    """A single search result. Available fields include url, url_title,
    snippet, rss, short_host, short_host_url, and display_url.
    """

class ResultSet(ResponseObject):
    """A set of search results. Behaves as an immutable sequence
    containing Result objects (accessible via iteration or
    subscripting). Additional available fields include q, noslash_q,
    total_num, num_elem_start, num_elem,end, nav_page_range_start,
    nav_page_range_end, tag_switches, sug_slash, and
    universal_total_results.
    """
    def __iter__(self):
        for result in self.data['RESULT']:
            yield Result(result)

    def __getitem__(self, index):
        return Result(self.data['RESULT'][index])

    def __len__(self):
        return len(self.data['RESULT'])

class Blekko(object):
    def __init__(self, auth=None, source=None):
        """Create an API object. Either `auth` or `source` must be
        provided to identify the application (use whichever was assigned
        to you by Blekko).
        """
        if not auth and not source:
            raise BlekkoError('API key not provided')
        self.auth = auth
        self.source = source

    def _request(self, path, params):
        """Make a (rate-limited) request to the Blekko server and return
        the result data.
        """
        params = dict(params)  # Make a copy.
        if self.auth:
            params['auth'] = self.auth
        else:
            params['source'] = self.source
        query = urllib.urlencode(params)
        url = "{}{}?{}".format(BASE_URL, path, query)
        return _http_request(url)

    def query(self, terms, page=0):
        """Perform a search and return a ResultSet object."""
        data = self._request('/ws/', {
            'q': terms + ' /json',
            'p': str(page),
        })
        return ResultSet(json.loads(data))

    def pagestats(self, url):
        """Get page statistics for a URL and return a dictionary of
        available information.
        """
        data = self._request('/api/pagestats', {
            'url': url,
        })
        return json.loads(data)
ENDPYTHON
