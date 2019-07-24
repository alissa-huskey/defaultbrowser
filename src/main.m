//
//  main.m
//  defaultbrowser
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define CASE(...)           if ([__VA_ARGS__ containsObject:__s__])
#define SWITCH(s)           for (NSString *__s__ = (s); ; )
#define DEFAULT

#define COMMAND_DEFAULT     @"help"
BOOL QUIET = NO;

void usage() {

	NSString *usage = @"\
COMMANDS:\n\
  -ls, list         list all available HTTP handlers and show the current setting\n\
  -g,  get          print the current browser\n\
  -h, help          show this screen\n\
  set <BROWSER>     set the default browser to <BROWSER>\n\
  \n\
OPTIONS:\n\
  -q, --quiet       quiet mode \n\
\n\
EXAMPLES:\n\
  defaultbrowser set chrome\n\
  defaultbrowser set \"google chrome\"\n\
  defaultbrowser set com.google.chrome\n\
";

	printf("%s\n", [usage UTF8String]);
}

void error(NSString *message) {
  printf("\e[0;31m[ERROR]\e[0m %s\n", [message UTF8String]);
}

void info(NSString *message) {
  if(QUIET) {
    return;
  }
  printf("\e[0;34m>\e[0m %s\n", [message UTF8String]);
}

NSBundle* getBundle(NSString *id) {
  NSArray *urls = CFBridgingRelease(LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef _Nonnull)(id), NULL));
  if (urls == nil || [urls count] == 0) {
    return nil;
  }
  NSBundle *bundle = [NSBundle bundleWithURL:urls[0]];
  return bundle;
}

NSString* getBrowserName(NSBundle* bundle) {
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^/Applications/(.+?).app" options:0 error:nil];
  NSString *path = [bundle bundlePath];
  NSTextCheckingResult *match = [regex firstMatchInString:path
                                       options:0
                                       range:NSMakeRange(0, [path length])];

  if(!match) {
    error([NSString stringWithFormat:@"unable to parse path: '%s'", [path UTF8String]]);
  }

  NSRange needleRange = [match rangeAtIndex: 1];
  NSString *name = [path substringWithRange:needleRange];

  return name;
}

NSString* getBrowserNameFromID(NSString* id) {
  NSBundle *bundle = getBundle(id);
  if(!bundle) {
    return nil;
  }
  NSString *name = getBrowserName(bundle);
  return name;
}

NSMutableDictionary* getBrowsers() {
    NSArray *appIDs =
      (__bridge NSArray *) LSCopyAllHandlersForURLScheme(
        (__bridge CFStringRef) @"http"
      );

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    for (int i = 0; i < [appIDs count]; i++) {
        NSString *appID = [appIDs objectAtIndex:i];
        NSBundle *bundle = getBundle(appID);
        if(!bundle) {
          continue;
        }
        dict[appID] = getBrowserName(bundle);
    }

    return dict;
}

NSMutableDictionary* getHandlers() {
  NSMutableDictionary *browsers = getBrowsers();
  NSMutableDictionary *handlers = [NSMutableDictionary dictionary];

  for (NSString *id in browsers) {
    NSArray *parts = [browsers[id] componentsSeparatedByString:@" "];
    handlers[[id lowercaseString]] = id;
    handlers[[browsers[id] lowercaseString]] = id;

    for (NSString *part in parts) {
      part = [part lowercaseString];
      if(handlers[part]) {
        // if there are any duplicate words, both lose
        handlers[part] = nil;
      } else {
        handlers[part] = id;
      }
    }
  }

  return handlers;
}

NSString* getCurrentBrowser() {
    NSString *id =
        (__bridge NSString *) LSCopyDefaultHandlerForURLScheme(
            (__bridge CFStringRef) @"http"
        );

    return id;
}

void set_default_handler(NSString *url_scheme, NSString *handler) {
    LSSetDefaultHandlerForURLScheme(
        (__bridge CFStringRef) url_scheme,
        (__bridge CFStringRef) handler
    );
}

int execute_list_command(NSMutableDictionary *browsers, NSString *current_browser_id) {

    for (NSString *id in browsers) {
      char *mark = [id isEqual:current_browser_id] ? "* " : "  ";
          printf("%s%s\n", mark, [browsers[id] UTF8String]);
      }

    return 0;
}

int execute_get_command(NSString *current_browser_id) {
  NSString *name = getBrowserNameFromID(current_browser_id);
  printf("%s\n", [name UTF8String]);

  return 0;
}

int execute_set_command(NSString *target, NSMutableDictionary *handlers, NSString *current_browser_id) {
    NSString *target_handler = handlers[[[target lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];

    if(!target_handler) {

      error([NSString stringWithFormat:@"invalid browser: '%s'", [target UTF8String]]);
      return 1;

    } else if ([target_handler isEqual:current_browser_id]) {

      info([NSString stringWithFormat:@"already set to: %s", [target_handler UTF8String]]);
      return 0;

    } else {

      info([NSString stringWithFormat:@"setting to: '%s'", [target_handler UTF8String]]);
    }

    set_default_handler(@"http", target_handler);
    set_default_handler(@"https", target_handler);

    return 0;
}

int execute_help_command() {
  printf("defaultbrowser - manage the default browser setting\n\n");
  usage();
  return 0;
}

int main(int argc, const char *argv[]) {
    NSString *target;
    NSString *command;
    int rtncode;

    for( int i = 1; i < argc; i++) {
      NSString *arg = [NSString stringWithUTF8String:argv[i]];
      SWITCH( arg ) {
        CASE (@[ @"-q", @"--quiet" ]) {
          QUIET = YES;
          break;
        }
        CASE (@[ @"list", @"-ls" ]) {
          command = @"list";
          break;
        }
        CASE (@[ @"get", @"-g" ]) {
          command = @"get";
          break;
        }
        CASE (@[ @"set", @"-s" ]) {
          command = @"set";
          break;
        }
        CASE (@[ @"help" ]) {
          command = @"help";
          break;
        }
        DEFAULT {
          if(command) {
            target = arg;
          }
          break;
        }
      }
    }

    if(!command) {
      command = COMMAND_DEFAULT;
    }

    @autoreleasepool {
        // Get all HTTP handlers
        NSMutableDictionary *handlers = getHandlers();
        NSMutableDictionary *browsers = getBrowsers();

        // Get current HTTP handler
        NSString *current_browser_id = getCurrentBrowser();

        SWITCH( command ) {
            CASE (@[ @"list" ]) {
                rtncode = execute_list_command(browsers, current_browser_id);
                break;
            }
            CASE (@[ @"get" ]) {
                rtncode = execute_get_command(current_browser_id);
                break;
            }
            CASE (@[ @"help" ]) {
                rtncode = execute_help_command();
                break;
            }
            CASE (@[ @"set" ]) {
                rtncode = execute_set_command(target, handlers, current_browser_id);
                break;
            }
            DEFAULT {
                rtncode = 1;
                break;
            }
        }
    }

    return rtncode;
}
