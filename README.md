#  ARCHIVED: xmtp-inbox-ios

![Status](https://img.shields.io/badge/Project_Status-Archived-lightgrey)

This **archived** repo provides the XMTP Inbox iOS app, which is no longer supported.

For an alternative solution, see the [example app](https://github.com/xmtp/xmtp-ios/tree/main/XMTPiOSExample) provided by the `xmtp-ios` SDK.

## Getting started

### Configure Infura

Add your Infura Key as a [build configuration setting](https://help.apple.com/xcode/mac/11.4/#/deve97bde215) in a file called `Secrets.xcconfig` in Xcode.

```
File -> New -> File... -> Configuration Settings File -> **Secrets.xcconfig**
```

Then add the following as a [static environment variable](https://help.apple.com/xcode/#/dev745c5c974).

```
INFURA_KEY = {REPLACE_WITH_YOUR_KEY}
```

If you do not have an Infura Key, you can follow [these instructions](https://blog.infura.io/getting-started-with-infura-28e41844cc89/) to get one.
