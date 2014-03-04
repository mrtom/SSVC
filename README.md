# SSVC - A simple version checking client for iOS

## What is SSVC?
SSVC is a simple version checking client for iOS. It connects to a server you designate and checks if a more recent version is available. It passes this information back to a delegate where you decide what to do next - for example displaying a prompt to take somebody to the App Store.

## Installation

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
  "SSVCLatestVersionKey": "abcdefg",
  "SSVCLatestVersionNumber": 2
 }
 ```

### Definitions

| Name | Description | Permitted Values | Required | Default |
| ---- | ----------- | ---------------- | -------- | ------- |
| SSVCUpdateAvailable | Is a more recent version of your application available? | 1 (Yes) or 0 (No) | No | |
| SSVCUpdateRequired | Is the more recent version of your application a required update? For example, after a breaking change in your API | 1 (Yes) or 0 (No) | No | |
| SSVCUpdateAvailableSince | The date since the most recent update was available, as an ISOxxx timestamp (i.e. seconds since the epoc, January 1st 1970 | No | |


## Customising Usage