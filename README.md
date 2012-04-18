# autolink.vim

This vim plugin automatically finds and inserts URLs for links in Markdown and
ReST documents.

## Search for URLs

autolink.vim uses the [Blekko][] search engine API to find URLs matching the
link IDs in [Markdown][] and [reStructuredText][] reference-style links. It
automatically inserts the first link found.

[Markdown]: http://daringfireball.net/projects/markdown/
[reStructuredText]: http://docutils.sourceforge.net/rst.html
[Blekko]: http://blekko.com/

For example, say you have this document:

    I think [Markdown][] is really great.

    [Markdown]: need a URL for this

With your cursor on the last line, you can type ``<leader>ac`` (for
*auto-complete* link) and the last line will become:

    [Markdown]: http://daringfireball.net/projects/markdown/

Behind the scenes, the plugin searches on Blekko for the word "Markdown" and
inserts the first result's URL, a reasonable guess for a relevant link on the
subject, in the appropriate place. This also works in ReST documents on
hyperlink target lines like `.. _Markdown: link goes here`.

## Create Link Definitions

This plugin can help you insert the markup for reference-style links. For
example, suppose you have just typed this paragraph:

    I prefer the [vim text editor][vim].

Type ``<leader>am`` (for *auto-make* link) to add a definition for the link
below the current paragraph:

    I prefer the [vim text editor][vim].

    [vim]: 

This also works in ReST for reference-style links like `` `foo`_``.

The plugin is careful to insert newlines between text paragraphs and blocks of
link references to make your document look nice.

## All Together Now

To insert and complete a link definition in one fell swoop, use ``<leader>al``
(for *auto-link*, the name of this plugin). This will add a reference to your
link after the current paragraph, fill it out with a search result, and then
jump back to your current cursor position to let you keep writing. (If your leader is `\`, then it's like typing ``mq\am\ac`q``.)

# Installing

The plugin requires vim to be built with Python bindings (to communicate with
the Blekko API). If you're using [Pathogen][], just clone this repository into
your bundles directory (and run `:Helptags`). Otherwise, place files in
`plugin`, `autoload`, and `doc` into the corresponding directories in `~/.vim`.

[Pathogen]: https://github.com/tpope/vim-pathogen

# To-Do

* Automatic activation when completing a link reference (i.e., after typing `]`
  in Markdown)?
* Optionally use the link text, rather than the reference ID, as the search
  terms.
* Options to use subsequent results (if the first link isn't good).
* Handle web service errors (avoid inserting "None", possible retry).
* Add to the vimscripts directory.

# Credits

This plugin is by me, Adrian Sampson. This is my first bit of vimscript hackery
and is very experimental---I apologize for weirdnesses arising from my
unfamiliarity with writing vim plugins.

The first-search-result idea is shamelessly borrowed from [Brett Terpstra][],
whose ingenious ["Lucky Link" service for Mac OS X][luckylink] is the first
place I saw this kind of functionality.

[luckylink]: http://brettterpstra.com/automated-search-and-link-text-service/
[Brett Terpstra]: http://brettterpstra.com/

The code is available under the [MIT license][]. The plugin contains an inlined
copy of [python-blekko][], which is under the same license. My thanks to the
kind folks at [Blekko][] for providing free access to their search API.

[MIT license]: http://www.opensource.org/licenses/MIT
[python-blekko]: https://github.com/sampsyo/python-blekko 
