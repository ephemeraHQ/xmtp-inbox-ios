#!/bin/sh

#  ci_post_clone.sh
#  xmtp-inbox-ios
#
#  Created by Pat Nakajima on 2/1/23.
#  

cd $CI_WORKSPACE
echo "INFURA_KEY = $INFURA_KEY" > "Secrets.xcconfig"
