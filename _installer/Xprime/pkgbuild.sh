#!/bin/bash

# Your AppleID, TeamID, Password and Name (An app-specific password NOT! AppleID password)
if [ -z "$APPLE_ID" ]; then
    source ../notarization.sh
fi

PROJECT_NAME=xprime

echo Build the flat package
pkgbuild \
  --root package-root \
  --identifier uk.insoft.$PROJECT_NAME \
  --version 1.0 \
  $PROJECT_NAME.pkg

echo Sign the package
productsign \
  --sign "Developer ID Installer: $YOUR_NAME ($TEAM_ID)" \
    $PROJECT_NAME.pkg \
    $PROJECT_NAME-signed.pkg

echo Submit for notarization using your keychain profile
xcrun notarytool submit $PROJECT_NAME-signed.pkg \
  --keychain-profile "mycreds" \
  --wait

echo Staple the notarization ticket
xcrun stapler staple $PROJECT_NAME-signed.pkg

echo font-signed.pkg is now signed, notarized, and ready for distribution

# Verify
xcrun stapler validate $PROJECT_NAME-signed.pkg

# Gatekeeper
spctl --assess --type install --verbose $PROJECT_NAME-signed.pkg

rm $PROJECT_NAME.pkg
mv $PROJECT_NAME-signed.pkg ../$PROJECT_NAME.pkg
