# SSVC - A simple version checking client for iOS

[![Build Status](https://travis-ci.org/mrtom/SSVC.png)](https://travis-ci.org/mrtom/SSVC)

## What is SSVC?
SSVC is a simple version checking client for iOS. It connects to a server you designate and checks if a more recent version of your App is available. You decide how to consume this information and what to do next - for example displaying a prompt to take somebody to the App Store.

## Installation

### Using CocoaPods
* Add 'SSVC' to your Podfile, with something like:

 `pod 'SSVC',       '~> 0.0.1'`
* Run `pod install`, and open the Xcode workspace.
* See http://cocoapods.org/ for more information on managing your dependencies with CocoaPods.

### By hand
* Download the project from Github (https://github.com/mrtom/SSVC), and unzip
* Copy ```SSVC.xcodeproj``` into the 'frameworks' folder within Xcode for your project
* Link ```libSSVC.a``` to your project:
    * Select your main project in Xcode (usually at the top)
    * Select your target
    * Click 'Build Phases'
    * Click the + icon at the bottom of 'Link Binary With Libraries'
    * Select 'libSSVC.a'

## Basic Usage

##### The easiest way to to see SSVC in action is to check out the Sample App. You can download this under 'SSVCSample' from the GitHub repo.

The primary class of SSVC is called... SSVC! For the most basic usage:

* Add the URL of your server to your main plist file. Use the key ```SSVCCallbackURL``` and a URL for the value. This URL must be fully qualified and may contain GET parameters.

* Import SSVC into your root view controller:

```objc
    #import <SSVC/SSVC.h>
```

* Create a basic instance of the version checker object somewhere, for example in your designated initialiser:

```objc
    SSVC *versionChecker = [SSVC new];
```

* Call ```checkVersion:```:

```objc
  [versionChecker checkVersion];
```

* This will cause SSVC to send an HTTP GET request to the server you specified above with the following parameters:
    * ```SSVCLatestVersionKey``` - The version key of the application currently running, i.e. 1.0
    * ```SSVCLatestVersionNumber``` - The vesrion (build) number of the application currently running, i.e. 16809984
    * ```SSVCLanguage``` - The `NSLocaleLanguageCode` returned from `NSLocale`
    * ```SSVCCountry``` - The `NSLocaleCounryCode` returned from `NSLocale`
    * ```SSVCClientProtocolVersion``` - The version of the protocol used by SSVC, currently 1

SSVC expects your server to return a simple JSON object, with the following format. Note, all fields are optional:

```JSON
{
  "SSVCMinimumSupportedVersionNumber": 16800000,
  "SSVCLatestVersionAvailableSince": 1388750400,
  "SSVCLatestVersionKey": "1.0",
  "SSVCLatestVersionNumber": 16809984
 }
 ```

Because all fields are optional, you may omit either or both of the latest version fields (`SSVCLatestVersionKey` & `SSVCLatestVersionNumber`). If you omit both, the response is not going to be very useful. If you include both, the response will transparently include both values without confirming that they are equivalent, and the version number will take precedence over the version key when determining if an update is available.

### JSON Response Definitions

| Name | Description | Permitted Values/Type | Required | Default |
| ---- | ----------- | --------------------- | -------- | ------- |
| SSVCMinimumSupportedVersionNumber | The minimum version number of your client or API now supported. This allows you to tell the client to force an update | An Unsigned Integer | No | `SSVCNoMinimumSupportedVersionNumber` (0) |
| SSVCLatestVersionAvailableSince | The date since the most recent update was available | Any valid Unix timestamp (i.e. seconds since the epoc, January 1st 1970, UTC - http://en.wikipedia.org/wiki/Unix_timestamp) | No | ```[NSDate distantPast]``` |
| SSVCLatestVersionKey | The iOS Version Key for your latest build, as found in your App bundle | A string of the form X.Y.Z, for X = [0-99] and Y & Z = [0-9] | No | `SSVCNoVersionKey` ("0.0.0") |
| SSVCLatestVersionNumber | The iOS Version Number for your latest build, as found in your App bundle | An Unsigned Integer | No | `SSVCNoVersionNumber` (0) |

### SSVCResponse
Once SSVC has received the response from your server, it constructs an ```SSVCResponse``` object. This object wraps up the JSON response in a more friendly Objective-C API then saves it to disk using ```NSUserDefaults```, under the key ```SSVCResponseFromLastVersionCheck```. This probably isn't the simplest way of accessing the response - see 'Customising Usage' below for more information on how to register for updates when a new response is available.

An ```SSVCResponse``` objects contains the following (read only) properties, mapping to the fields in the JSON response above:

| Name | Type |
| ---- | ---- |
| updateAvailable | ```BOOL``` |
| updateRequired  | ```BOOL``` |
| minimumSupportedVersionNumber | ```NSDate *```|
| updateAvailableSince | ```NSDate *``` |
| latestVersionKey | ```NSString *``` |
| latestVersionNumber | ```NSNumber``` |

Like SSVC objects, instances of SSVCResponse are immutable (and thus threadsafe), so you can pass them around as much as you like. They also conform to the ```<NSCoding>``` protocol, so you can archive them easily.

## Customising Usage

There are a number of additional initialiser methods you can use to help customise behaviour of SSVC. For example, you can pass an ```NSString *``` as the URL for your server rather than adding it to the plist. Other configuration options include:

#### Registering for callbacks

You can request callbacks from SSVC whenever it succeeds (and fails) to receive updates, using the initialiser

```
- (id)initWithCompletionHandler:(ssvc_fetch_success_block_t)success
                 failureHandler:(ssvc_fetch_failure_block_t)failure;
```

The success block will be passed an instance of ```SSVCResponse```, and the failure block is passed an instance of ```NSError```. The success block is guaranteed to be run on the main thread. However, please note this is not true for the failure block. (Why? See the FAQ).

#### Scheduling regular version checks using SSVCScheduler:
```SSVCScheduler``` instances instruct SSVC how often to automatically schedule version checks. You pass it's initialiser a typed enum, ```SSVCSchedulerRunPeriod```, detailing the schedule period. The following options are available:

* ```SSVCSchedulerDoNotSchedule``` - Do not schedule regular checks
* ```SSVCSchedulerScheduleHourly``` - Check once per hour
* ```SSVCSchedulerScheduleDaily``` - Check once per day
* ```SSVCSchedulerScheduleWeekly``` - Check once per week
* ```SSVCSchedulerScheduleMonthly``` - Check once per month

The checks only occur if your App is running. When you initialise an SSVC object, it checks when the last version check was performed and schedules an update accordingly. Thus, if the app ins't running at the time the check should be made, your App will simply make the check the next time it is launched (and an SSVC object created).

If you want to schedule a more complex update strategy, you should use ```NSTimer``` (or something similar) and call ```[SSVC checkVersion]``` at the appropriate time.

## FAQ:

### Is SSVC free to use?
Yes, the project is licensed under the pervasive MIT License. See http://opensource.org/licenses/MIT for more information.

### Why do I have to provide my own server?
As far as I know there aren't any open APIs where this information can be retrieved from the Web. If you know others, please let me know!

[Update: I'm looking into using the Apple Affiliate API. However, there are still reasons to support custom URLs as well. For example, dealing with beta testers using Test Flight]

### Why do you insist on calling the success block on the main thread?
For the most part, I anticipate developers will want to invoke some sort of UI change when the update checker indicates an update is available. As UIKit isn't threadsafe, such updates need to be performed on the main thread.

I think it makes sense to assume some consumers of SSVC don't want to worry about which thread their code runs on, so forcing the success block to run on the main thread minimises effort for the general case. And if you're doing something complicated enough that you know you want to use another thread/queue, you probably already know both how to do this, and which queue you want your success block run on.

### Why don't you call the failure block on the main thread?
Failing to receive a response from your version checker is unlikely to warrent a using facing/UI altering error. I suspect in most cases a developer may want to log this and move on, or perhaps just ignore this failure case altogether. In which case, performing the block on the main thread is potentially wasteful. If you do require this, however, it's simple enough. Just wrap the contents of your block in a GCD queue for the main thread, thus:

```objc
dispatch_queue_t mainQ = dispatch_get_main_queue();
dispatch_async(mainQ, ^{
  // Your code here
});
```
