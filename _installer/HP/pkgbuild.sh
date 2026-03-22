#!/bin/bash

# Your AppleID, TeamID, Password and Name (An app-specific password NOT! AppleID password)
if [ -z "$APPLE_ID" ]; then
    source ../notarization.sh
fi

NAME=hp

# HP
pkgbuild --identifier uk.insoft.$NAME \
         --root package-root \
         --version 1.5 --install-location / \
         --scripts scripts \
         $NAME.pkg
         
productsign --sign "Developer ID Installer: $YOUR_NAME ($TEAM_ID)" $NAME.pkg $NAME-signed.pkg

xcrun notarytool submit --apple-id $APPLE_ID \
                        --password $PASSWORD \
                        --team-id $TEAM_ID \
                        --wait $NAME-signed.pkg
                        
# Staple
xcrun stapler staple $NAME-signed.pkg

# Verify
xcrun stapler validate $NAME-signed.pkg

# Gatekeeper
spctl --assess --type install --verbose $NAME-signed.pkg

rm $NAME.pkg
mv $NAME-signed.pkg ../$NAME.pkg
