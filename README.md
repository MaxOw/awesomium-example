#Awesomium with Haskell#

This is a simple usage example of Awesomium bindings for haskell.

[Awesomium][1] is an windowless port of Chromium/WebKit. You can use
it to leverage the power of web browsers into your application.

Specifically my motivation for writing this wrapper was for the use in
gamedev. The advantages of using this approach, as opposed to writing
dedicated GUI, are numerous; you can use the powers of HTML/CSS/JS and
all the tools and frameworks (like jQuery/jQueryUI, &c.) that ware and
constantly are created by webdevelopers around the globe, and more
importantly, you can push the GUI creation to the graphic/designer as
it is more likely for him to be familiar with the web tools and
languages. You can even employ your users, letting them play with the
UI as they please, and later merge the more popular modes into the
game. As for the disadvantages I guess it would be the performance.
Obviously the dedicated GUI will be faster.

For the commercial example, AFAIK people at [Wolfire][2] are using it
in their game [Overgrowth][3].

Also, before you jump your guns, a friendly warning. Awesomium is
free for non-commercial projects, but for commercial usage (if your
company revenue last year was over $100K) you will need to pay $3K for
a license. For the details consult their webpage.

##Instalation##

Firstly, you will need to download shared library from the
http://awesomium.com and install it on your system. You should find
the installation process described in the README file.

Specifically, for Ubuntu:

> To install Awesomium, you'll need to add the shared library to
> your system's library search path. On Ubuntu, you can use the
> following commands:
> 
>     cd awesomium_v1.6.5_sdk_linux32
>     sudo mkdir /usr/lib/awesomium-1.6.5
>     sudo cp -r build/bin/release/* /usr/lib/awesomium-1.6.5
>     sudo ldconfig /usr/lib/awesomium-1.6.5

Next, you'll need to download and install bindings from hackage;

If, in the previous step you have installed the shared library in
a different path than `/usr/lib/awesomium-1.6.5` you will first have
to call:

    cabal install awesomium-raw --extra-lib-dirs="<your-path>"

Otherwise you just have to use this commands:

    cabal install awesomium
    cabal install awesomium-glut

##Usage Example##

The example<sup>1</sup>, maybe not very impressive one, should have
everything to get you started, so you should simply dive into the
code.

Of the more interesting parts, I think, communication with JavaScript
maybe worth noting.

To create API that you can call from JavaScript first you have to
register a handler and specify global object and methods:

```haskell
setCallbackJS wv (handle)

createObject wv "Application"
setObjectCallback wv "Application" "quit"
setObjectCallback wv "Application" "etc"
```

Then you can easily handle callbacks from js with the function of the
form:

```haskell
handle :: WebView -> String -> String -> [Value] -> IO ()
```

And where function arguments are list of [Data.Aeson.Values][4], so
you can easily parse it for any type that provides instance of
`FromJSON` which can be easily automated for example by using
`DeriveGeneric` (as described [here][5]).

Similarly, you can call javascript functions with (surprise, surprise)
`callJavascriptFunction` and providing ToJSON for any types that you
may want to pass as arguments.

And this point I'd love to direct you, for details, to the package
documentation on hackage. Sadly, however, hackage fails to compile the
library because it cannot localize the shared lib and subsequently
fails to generate the documentation files (if anyone knows how to get
around this, let me know). So your options are to generate it locally
or simply dive into the [code][6].

----------------------------------------------------------------------

1. I would like to note that this is only an example code, so there
   are some practises that I wouldn't recommend you to follow, like
   having global mutable state (you should better check some FRP
   framework). Also my web-fu is not very high, and that's why it may
   not look very pretty.

##Acknowledgement##

One, [Tom Savage][7], has written similar bindings ([link][8]) and
though incomplete they were certainly very useful, as any previous
work usually is.

[1]: http://awesomium.com
[2]: http://www.wolfire.com
[3]: http://www.wolfire.com/overgrowth
[4]: http://hackage.haskell.org/packages/archive/aeson/0.6.0.2/doc/html/Data-Aeson.html#t:Value
[5]: http://hackage.haskell.org/packages/archive/aeson/0.6.0.2/doc/html/Data-Aeson.html#t:FromJSON
[6]: https://github.com/MaxOw/awesomium
[7]: https://github.com/tcsavage
[8]: https://github.com/tcsavage/awesomium
