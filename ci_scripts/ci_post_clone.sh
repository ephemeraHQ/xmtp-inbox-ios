#!/bin/sh

#  ci_post_clone.sh
#  xmtp-inbox-ios
#
#  Created by Pat Nakajima on 2/1/23.
#  

echo "INFURA_KEY = $INFURA_KEY" > "$CI_WORKSPACE/Secrets.xcconfig"
