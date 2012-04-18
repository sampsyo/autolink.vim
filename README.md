autolink.vim
============

Automatically find and insert URLs for links in Markdown and ReST documents.

This vim plugin uses the [Blekko][] search engine API to find URLs matching the
link IDs in [Markdown][] and [reStructuredText][] reference-style links. It
automatically inserts the first link found.

For example, say you have this document:

    I think [Markdown][] is really great.

    [Markdown]: need a URL for this

With your cursor on the last line, you can type ``<leader>al`` (for
*auto-link*) and the last line will become:

    [Markdown]: http://daringfireball.net/projects/markdown/

Behind the scenes, the plugin searches on Blekko for the word "Markdown" and
inserts the first result's URL, a reasonable guess for a relevant link on the
subject, in the appropriate place. This also works in ReST documents on
hyperlink target lines like `.. _Markdown: link goes here`.

[Blekko]: http://blekko.com/
[Markdown]: http://daringfireball.net/projects/markdown/
[reStructuredText]: http://docutils.sourceforge.net/rst.html

Using the Plugin
----------------

The plugin requires vim to be built with Python bindings (to communicate with
the Blekko API). If you're using [Pathogen][], just clone this repository into
your bundles directory. Otherwise, place the `autolink.vim` file into your
`plugins` directory.

[Pathogen]: https://github.com/tpope/vim-pathogen

To-Do
-----

* Insert link definitions automatically. There should be a command that takes
  the link reference under the cursor, creates a definition for it after the
  current paragraph, and optionally searches for a link in one fell swoop. This
  could even be activated automatically when completing a link reference (i.e.,
  after typing `]` in Markdown).
* Optionally use the link text, rather than the reference ID, as the search
  terms.
* Options to use subsequent results (if the first link isn't good).
* More robust link insertion macros.
* Include vim help files.
* Move code to an "autoload" file?
* Add to the vimscripts directory.

Credits
-------

This plugin is by me, Adrian Sampson. This is my first bit of vimscript hackery
and is very experimental---I apologize for weirdnesses arising from my
unfamiliarity with writing vim plugins.

The code is available under the [MIT license][]. The plugin contains an inlined
copy of [python-blekko][], which is under the same license.

[MIT license]: http://www.opensource.org/licenses/MIT
[python-blekko]: https://github.com/sampsyo/python-blekko 
