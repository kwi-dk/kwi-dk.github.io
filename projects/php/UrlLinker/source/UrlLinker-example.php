<!doctype html>
<html>
<head>
<title>UrlLinker Example</title>
</head>
<body>
<p>
<?php

require("UrlLinker.php");

$text = <<<EOD
Here are some URLs:
stackoverflow.com/questions/1188129/pregreplace-to-detect-html-php
Here's the answer: http://www.google.com/search?rls=en&q=42&ie=utf-8&oe=utf-8&hl=en. What was the question?
A quick look at http://en.wikipedia.org/wiki/URI_scheme#Generic_syntax is helpful.
There is no place like 127.0.0.1! Except maybe http://news.bbc.co.uk/1/hi/england/surrey/8168892.stm?
Ports: 192.168.0.1:8080, https://example.net:1234/.
Beware of Greeks bringing internationalized top-level domains: xn--hxajbheg2az3al.xn--jxalpdlp.
And remember.Nobody is perfect.

<script>alert('Remember kids: Say no to XSS-attacks! Always HTML escape untrusted input!');</script>
EOD;

print(nl2br(htmlEscapeAndLinkUrls($text)));

?>
</p>
</body>
</html>
