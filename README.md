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
  defaultbrowser
  defaultbrower help
  defaultbrower get
  defaultbrower list
  defaultbrowser <browser>

options:
  -h, help          show this screen
  -g, get           outputs the current browser only
  -ls, list         list all available HTTP handlers and show the current setting (default if no arguments are passed)
  <browser>         set the default browser to <browser>
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
