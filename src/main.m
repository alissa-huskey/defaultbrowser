//
//  main.m
//  defaultbrowser
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define CASE(...)                       if ([__VA_ARGS__ containsObject:__s__])
#define SWITCH(s)                       for (NSString *__s__ = (s); ; )
#define DEFAULT


NSString* app_name_from_bundle_id(NSString *app_bundle_id) {
    return [[app_bundle_id componentsSeparatedByString:@"."] lastObject];
}

NSMutableDictionary* get_http_handlers() {
    NSArray *handlers =
      (__bridge NSArray *) LSCopyAllHandlersForURLScheme(
        (__bridge CFStringRef) @"http"
      );

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    for (int i = 0; i < [handlers count]; i++) {
        NSString *handler = [handlers objectAtIndex:i];
        dict[[app_name_from_bundle_id(handler) lowercaseString]] = handler;
    }

    return dict;
}

NSString* get_current_http_handler() {
    NSString *handler =
        (__bridge NSString *) LSCopyDefaultHandlerForURLScheme(
            (__bridge CFStringRef) @"http"
        );

    return app_name_from_bundle_id(handler);
}

void set_default_handler(NSString *url_scheme, NSString *handler) {
    LSSetDefaultHandlerForURLScheme(
        (__bridge CFStringRef) url_scheme,
        (__bridge CFStringRef) handler
    );
}

int execute_list_mode(NSMutableDictionary *handlers, NSString *current_handler_name) {
    // List all HTTP handlers, marking the current one with a star
    for (NSString *key in handlers) {
        char *mark = [key isEqual:current_handler_name] ? "* " : "  ";
            printf("%s%s\n", mark, [key UTF8String]);
        }

    return 0;
}

int execute_get_mode(NSString *current_handler_name) {
    // Just ouput the current setting
    printf("%s\n", [current_handler_name UTF8String]);

    return 0;
}

int execute_set_mode(NSString *target, NSMutableDictionary *handlers, NSString *current_handler_name) {
    NSString *target_handler_name = target;

    if ([target_handler_name isEqual:current_handler_name]) {
      printf("%s is already set as the default HTTP handler\n", [target UTF8String]);

      return 1;

    } else {
	NSString *target_handler = handlers[target_handler_name];

	if (target_handler != nil) {
	    // Set new HTTP handler (HTTP and HTTPS separately)
	    set_default_handler(@"http", target_handler);
	    set_default_handler(@"https", target_handler);
	} else {
	    printf("%s is not available as an HTTP handler\n", [target UTF8String]);

	    return 1;
	}
    }

    return 0;
}

int execute_help_mode() {

	NSString *usage = @"\nusage:\n\
  defaultbrowser\n\
  defaultbrower help\n\
  defaultbrower get\n\
  defaultbrower list\n\
  defaultbrowser set <browser>\n\
options:\n\
  -h, help          show this scre\n\
  -g, get           outputs the current browser on\n\
  -ls, list         list all available HTTP handlers and show the current setting (default if no arguments are passe\n\
  set <browser>     set the default browser to <browse\n\
";

	printf("%s\n", [usage UTF8String]);
	return 0;
}

int main(int argc, const char *argv[]) {
    NSString *target;
    NSString *mode;
    int rtncode;

    switch( argc ) {
	    case 1: // if no argument is passed, print out the list
		    target = @"none";
		    mode = @"list";
		    break;
	    case 2: // if one argument is passed, let's say it's the mode
		    target = @"none";
		    mode = [NSString stringWithUTF8String:argv[1]];
		    break;
	    case 3: // the only current two argument mode is set <browser>
		    target = [NSString stringWithUTF8String:argv[2]];
		    mode = [NSString stringWithUTF8String:argv[1]];
		    break;
    }

    @autoreleasepool {
        // Get all HTTP handlers
        NSMutableDictionary *handlers = get_http_handlers();

        // Get current HTTP handler
        NSString *current_handler_name = get_current_http_handler();

	SWITCH( mode ) {
		CASE (@[ @"list", @"-ls" ]) {
		    rtncode = execute_list_mode(handlers, current_handler_name);
		    break;
		}
		CASE ( @[ @"get", @"-g" ] ) {
		    rtncode = execute_get_mode(current_handler_name);
		    break;
		}
		CASE (@[ @"help" ]) {
		    rtncode = execute_help_mode();
		    break;
		}
		CASE (@[ @"set" ]) {
		    rtncode = execute_set_mode(target, handlers, current_handler_name);
		    break;
		}
		DEFAULT {
		    printf("%s command not recognized\n", [mode UTF8String]);
		    rtncode = 1;
		    break;
		}
	}
    }

    return rtncode;
}
