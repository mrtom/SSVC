# SSVC - A simple version checking client for iOS

## What is SSVC?
SSVC is a simple version checking client for iOS. It connects to a server you designate and checks if a more recent version is available. It passes this information back to a delegate where you decide what to do next - for example displaying a prompt to take somebody to the App Store.

## Installation

* Download the project from Github (https://github.com/mrtom/SSVC), and unzip
* Copy ````SSVC.xcodeproj``` into the 'frameworks' folder within Xcode for your project
* Link libSSVC.a to your project:
    * Select your main project in Xcode (usually at the top)
    * Select your target
    * Click 'Build Phases'
    * Click the + icon at the bottom of 'Link Binary With Libraries'
    * Select 'libSSVC.a'

## Basic Usage

The primary class of SSVC is called... SSVC! For the most basic usage:

* Add the URL of your server to your main plist file. Use the key "SSVCCallbackURL" and a URL string. This URL must be fully qualified and may contain GET parameters.

* Import SSVC into your root view controller:

```objc
    #import <SSVC/SSVC.h>
```

* Create a basic instance of the view checker object:

```objc
    SSVC *viewChecker = [SSVC new];
```

* Call ```'checkVersion:```':

```objc
  [viewChecker checkVersion];
```

* This will cause SSVC to send an HTTP GET request to the server you specified above with the follow parameters:
    * SSVCLatestVersionKey - The version key of your application, i.e. 1.0
    * SSVCLatestVersionNumber - The vesrion (build) number of your application, i.e. 4354667
    * SSVCClientProtocolVersion - The version of the protocol used by SSVC, currently 1

SSVC expects your server to return a simple JSON object, with the following format. Note, all fields are optional:

```JSON
{
  "SSVCUpdateAvailable": 1,
  "SSVCUpdateRequired": 0,
  "SSVCUpdateAvailableSince": 1388750400,
  "SSVCLatestVersionKey": "1.0",
  "SSVCLatestVersionNumber": 16809984
 }
 ```

### JSON Response Definitions

| Name | Description | Permitted Values/Type | Required | Default |
| ---- | ----------- | --------------------- | -------- | ------- |
| SSVCUpdateAvailable | Is a more recent version of your application available? | 1 (Yes) or 0 (No) | No | 0 |
| SSVCUpdateRequired | Is the more recent version of your application a required update? For example, after a breaking change in your API | 1 (Yes) or 0 (No) | No | 0 |
| SSVCUpdateAvailableSince | The date since the most recent update was available | Any valid Unix timestamp (i.e. seconds since the epoc, January 1st 1970, UTC - http://en.wikipedia.org/wiki/Unix_timestamp) | No | ```[NSDate distantPast]``` |
| SSVCLatestVersionKey | The iOS Version Key for your latest build, as found in your App bundle | A string of the form X.Y.Z, for X = [0-99] and Y & Z = [0-9] | No | 0.0.0 |
| SSVCLatestVersionNumber | The iOS Version Number for your latest build, as found in your App bundle | An Unsigned Integer | No | 0 |

### SSVCResponse
Once SSVC has received the response from your server, it constructs an ```SSVCResponse``` object. This object wraps up the JSON response in a more friendly Objective-C API, and saves it to disk using ```NSUserDefaults```, under the key ```SSVCResponseFromLastVersionCheck```. This probably isn't the simplest way of accessing the response - see 'Customising Usage' below for more information on how to register for updates when a new response is available.

Like SSVC objects, instances of SSVCResponse are immutable (and thus threadsafe), so you can pass them around as much as you like. They also conform to the ```<NSCoding>``` protocol, so you can archive them easily.

## Customising Usage

There are a number of additional initialiser methods you can use to help customise behaviour of SSVC. For example, you can pass an ```NSString *``` as the URL for your server rather than adding it to the plist. Other configuration options include:

### Registering for callbacks when SSVC succeeds or fails to fetch the latest version information:
// TODO

### Scheduling regular version checks using ```SSVCScheduler```:
// TODO

* ```

## FAQ:

### Is SSVC free to use?
Yes, the project is licensed under the pervasive MIT License. See http://opensource.org/licenses/MIT for more information.

### Why do I have to provide my own server?
As far as I know there aren't any open APIs where this information can be retrieved from the Web. If you know others, please let me know!

### Why don't you support CocoaPods?
Firstly, because I haven't had the time yet. And secondly, because I don't use it myself. If you want CocoaPods support, let me know and I'm more likely to get around to it - or send me a diff! :)