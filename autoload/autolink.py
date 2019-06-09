import re
import sys
import urllib.request
import urllib.parse
import vim
import webbrowser

def get_link(terms):
    query = 'https://duckduckgo.com/html/?q={}'.format(
        terms.strip().replace(' ','+')
    )
    html = urllib.request.urlopen(query).read().decode('utf8')
    for link in re.findall('div.*?web-result".*?href="(.*?)"', html, re.DOTALL):
        if "duckduckgo.com" not in link:
            return link

def open_search(terms):
    webbrowser.open('https://google.com/search?q=' + urllib.parse.quote(terms))
