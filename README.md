defaultbrowser
==============

Command line tool for setting the default browser (HTTP handler) in macOS.

Install
-------

Build it:

```
make
```

Install it into your executable path:

```
make install
```

Usage
-----

```
  COMMANDS:
  -ls, list         list all available HTTP handlers and show the current setting
  -g,  get          print the current browser
  -h, help          show this screen
  set <BROWSER>     set the default browser to <BROWSER>

EXAMPLES:
  defaultbrowser set chrome
  defaultbrowser set "google chrome"
  defaultbrowser set com.google.chrome
```

Examples
-----

list all available browsers and show the current setting
```
$ defaultbrowser list
  firefox
  chrome
* safari
```

set the browser to chrome
```
$ defaultbrowser set chrome
```

print the current browser
```
$ defaultbrowser get
safari
```





How does it work?
-----------------

The code uses the [macOS Launch Services API](https://developer.apple.com/documentation/coreservices/launch_services).

License
-------

MIT


Credits
-------

Forked from [kerma/defaultbrowser](https://github.com/kerma/defaultbrowser)
