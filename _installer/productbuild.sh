#!/bin/bash

# Your AppleID, TeamID, Password and Name (An app-specific password NOT! AppleID password)
if [ -z "$APPLE_ID" ]; then
    source notarization.sh
fi

NAME=primesdk
IDENTIFIER=uk.insoft.$NAME

source update_pkg_sizes.sh


productbuild --distribution distribution.dist \
             --resources Resources \
             --package-path . \
             $NAME-installer.pkg
             
productsign --sign "Developer ID Installer: $YOUR_NAME ($TEAM_ID)" $NAME-installer.pkg $NAME-installer-signed.pkg
                        
xcrun notarytool submit primesdk-installer-signed.pkg \
  --keychain-profile "mycreds" \
  --wait
                        
# Staple
xcrun stapler staple primesdk-installer-signed.pkg

# Verify
xcrun stapler validate primesdk-installer-signed.pkg

# Gatekeeper
spctl --assess --type install --verbose primesdk-installer-signed.pkg
             
rm $NAME-installer.pkg
mv $NAME-installer-signed.pkg ../xprime-universal.pkg




