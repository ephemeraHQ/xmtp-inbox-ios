#  xmtp-inbox-ios

## Getting Started

### Configure Infura

Add your Infura mainnet URL as an environment variable by editing your [Scheme](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project) in Xcode.

`Product -> Scheme -> Edit Scheme... -> Run -> Arguments`

Then add the following as an [Environment Variable](https://developer.apple.com/documentation/xcode/environment-variable-reference) and unselect the `Shared` checkbox before closing:

```
INFURA_MAINNET_URL={MAINNET_URL}
```

If you do not have an Infura URL, you can follow [these instructions](https://blog.infura.io/getting-started-with-infura-28e41844cc89/) to get one.
