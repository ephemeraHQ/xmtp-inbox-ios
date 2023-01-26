#  xmtp-inbox-ios

## Getting Started

### Configure Infura

Add your Infura Key as a [build configuration](https://help.apple.com/xcode/mac/11.4/#/deve97bde215) in Xcode.

```
File -> New -> File... -> Configuration Settings File -> Name the file **Secrets.xcconfig**
```

Then add the following as a [static environment varaible](https://help.apple.com/xcode/#/dev745c5c974).

```
INFURA_KEY = {REPLACE_WITH_YOUR_KEY}
```

If you do not have an Infura Key, you can follow [these instructions](https://blog.infura.io/getting-started-with-infura-28e41844cc89/) to get one.
