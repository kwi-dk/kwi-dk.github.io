#!/usr/bin/env python3
import html

import commonmark


abandoned_see_concept = '''
span.see {
    background: url('data:image/svg+xml,%3Csvg height="18" version="1.1" viewBox="0 0 122 90" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"%3E%3Cg id="a" transform="translate(-7.94 -7.94)"%3E%3Cellipse cx="39.7" cy="52.9" rx="26.5" ry="39.7" fill="%23fff" stroke="%23808080" stroke-width="2.65"/%3E%3Cellipse cx="52.9" cy="52.9" rx="10.6" ry="15.9"/%3E%3Ccircle cx="46.8" cy="44.5" r="5.29" fill="%23fff"/%3E%3C/g%3E%3Cuse transform="translate(58.2)" width="100%25" height="100%25" xlink:href="%23a"/%3E%3C/svg%3E') top left no-repeat;
    padding: 0 0 0 28px;
}

 (<span class="see"><a href="https://github.com/Unity-Technologies/p7zip-zstd/pull/1">compliance work example</a></span>)
'''

abandoned_css_anim = '''
.layeranim {
    height: 400px;
}
.layeranim img {
    position: absolute;
    height: 400px;
    width: 329px;
    animation-duration: 3s;
    animation-name: layeranim;
    animation-iteration-count: infinite;
}
.layeranim img:nth-child(1) { font-size: 0; }
.layeranim img:nth-child(2) { font-size: 10px; }
.layeranim img:nth-child(3) { font-size: 20px; }
.layeranim img:nth-child(4) { font-size: 30px; }
.layeranim img:nth-child(5) { font-size: 40px; }
.layeranim img:nth-child(6) { font-size: 50px; }
.layeranim img:nth-child(7) { font-size: 60px; }
.layeranim img:nth-child(8) { font-size: 70px; }

@keyframes layeranim {
    from {
        margin-left: 0;
    }
    50% {
        margin-left: 1em;
    }
    to {
        margin-left: 0;
    }
}
'''

class PageRenderer(commonmark.HtmlRenderer):
    list_context = None

    title = 'Portfolio – Søren Løvborg'

    begin_frame = '<div class="frame"><article>'
    end_frame = '</article></div>'

    css = '''\
html, body {
    background: #283d53 url(portfolio/stripe-1.png) center/100px;
    font: 16px/20px Helvetica, sans-serif;
    margin: 0;
    min-width: 350px;
    padding: 0;
}

h1 {
    margin: 44px 0 20px 0;
    font-size: 30px;
    font-weight: normal;
    line-height: 36px;
}

h2 {
    line-height: 24px;
    font-weight: normal;
    margin: 36px 0 20px 0;
}

p {
    margin: 20px 0;
}

a {
    text-decoration: none;
}

@media (any-hover: none) {
    abbr {
        text-decoration: none;
    }
}

.splash {
    background-size: cover !important;
    border-bottom: 1px solid #364a66;
    height: 60px;
    overflow: hidden;
    position: relative;
    visibility: hidden;
}
@media screen {
    .splash {
        box-shadow: inset 0px 0px 20px 5px rgba(0, 0, 0, 0.5);
        height: 700px;
        visibility: visible;
        margin: -180px 0;
    }
}
@media screen and (max-width: 1000px) {
    .splash {
        height: 500px;
        margin: -100px 0;
    }
}
.splash span {
    color: rgba(255, 255, 255, 0.75);
    font: 12px Helvetica, sans-serif;
    position: absolute;
    right: 16px;
    bottom: 4px;
    transform-origin: top right;
    transform: rotate(-90deg);
    width: 0;
    height: 0;
    white-space: nowrap;
}
@media screen and (max-width: 865px) {
    .splash span {
        bottom: 75px;
    }
}

.frame:first-child {
    margin-top: 0;
}

.frame {
    background: #fff;
    border-radius: 3px;
    border: 1px solid #eee;
    box-shadow: 0px 0px 20px 5px rgba(0, 0, 0, 0.25);
    margin: 30px auto 30px auto;
    max-width: 820px;
    position: relative;
    z-index: 100;
}

section {
    display: flex;
    flex-wrap: wrap;
    margin-left: -60px;
}
section > p {
    margin: 0 0 20px 60px;
}

article {
    padding: 0 0 16px 125px;
    overflow: hidden; /* needed for child margins */
}
article > * {
    margin-right: 180px;
}

article > img:first-child {
    float: right;
}

article > h2 > span:first-child,
article > p > span:first-child {
    display: block;
    position: absolute;
    margin-left: -100px;
    width: 85px;
    text-align: right;
    font-weight: bold;
    font-size: 14px;
    white-space: nowrap;
}

article > h2 > span:first-child {
    padding-top: 4px;
    line-height: 20px;
}

ul.leaflets {
    clear: right;
    float: right;
    font-size: 90%;
    list-style: none;
    margin: 0 40px 20px 20px;
    padding: 0;
}

.leaflets li, .leaflets a, .leaflets img {
    display: block;
    text-align: center;
    width: 102px;
}

.leaflets img {
    border: 1px solid;
    width: 100px;
    height: 141px;
    box-shadow: 1px 1px 2px rgba(0, 0, 0, 0.25);
    margin: 0 0 9px 0;
}

@media screen and (max-width: 780px) {
    article > * {
        margin-right: 130px;
    }
    ul.leaflets {
        width: 52px !important;
        font-size: 12px !important;
    }
    .leaflets li, .leaflets a {
        width: 52px !important;
    }
    .leaflets img {
        width: 50px !important;
        height: 70px !important;
    }
}

@media screen and (max-width: 720px) {
    h1 {
        margin-top: 24px;
    }
    ul {
        padding-left: 20px;
    }
    article {
        padding: 0 20px 16px 20px;
    }
    article > img:first-child {
        display: block;
        float: none;
        margin: 30px auto !important;
    }
    article > * {
        margin-right: 70px;
    }
    article > * > span:first-child {
        position: relative !important;
        margin: 0 !important;
        text-align: left !important;
        color: #666;
    }
    ul.leaflets {
        margin-right: 0px;
    }
}
'''

    def __init__(self, source):
        super().__init__()
        self.list_context = []

        parser = commonmark.Parser()
        ast = parser.parse(source)
        self.body = self.render(ast)

    def __str__(self):
        return f'''<!DOCTYPE HTML>
<html lang="en">
<head>
<meta charset="utf8" />
<title>{self.title}</title>
<meta name="viewport" content="width=device-width,initial-scale=1" />
<link rel="openid.server" href="http://kwi.dk/openid/" />
<link rel="openid.delegate" href="http://kwi.dk/openid/" />
<style>
{self.css}
</style>
</head>

<body>
{self.begin_frame}
{self.body}
{self.end_frame}
</body>
</html>
'''

    def attrs(self, node):
        attrs = super().attrs(node)
        if node.t == 'list' and self.list_context[-1]:
            attrs.append(['class', self.list_context[-1]])
        return attrs

    def code_block(self, node, entering):
        info_word, _, args = (node.info or '').partition(' ')
        if info_word == 'splash':
            text = node.literal.strip()
            self.lit(self.end_frame)
            self.cr()
            if args or text:
                self.lit(f'<div class="splash" style="{html.escape(args)}"><span>{html.escape(text)}</span></div>')
                self.cr()
            self.lit(self.begin_frame)
            self.cr()

        else:
            super().code_block(node, entering)

    def image(self, node, entering):
        if not entering and 'leaflets' in self.list_context:
            alt_html = self.buf[self._image_pos:]
            self.lit(f'" title="{alt_html}')
        super().image(node, entering)
        if entering:
            self._image_pos = len(self.buf)

    def list(self, node, entering):
        if entering:
            if node.list_data['bullet_char'] == '+':
                self.list_context.append('leaflets')
            else:
                self.list_context.append(None)
            #self.next_list_context = None
        super().list(node, entering)
        if not entering:
            self.list_context.pop()


if __name__ == '__main__':
    with open('portfolio.md', 'r') as f:
        source = f.read()

    page = PageRenderer(source)
    output = str(page).encode('utf-8')

    with open('../index.html', 'wb') as f:
        f.write(output)
