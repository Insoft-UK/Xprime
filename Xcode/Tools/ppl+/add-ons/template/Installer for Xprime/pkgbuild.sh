#!/bin/bash

# Your AppleID, TeamID, Password and Name (An app-specific password NOT! AppleID password)
if [ -z "$APPLE_ID" ]; then
    source notarization.sh
fi

if [ -z "$PROJECT_NAME" ]; then
    # Find the first .xcodeproj directory (not its contents)
    project_dir=$(find . -maxdepth 1 -type d -name "*.xcodeproj" | head -n 1)
    # Strip the .xcodeproj suffix to get the base name
    project_file=$(basename "$project_dir")
    PROJECT_NAME="${project_file%.xcodeproj}"
fi


# Executable
cp ../build/$(PROJECT_NAME) package-root/Applications/HP/Xprime.app/Contents/Resources/Developer/usr/bin/$(PROJECT_NAME)

# Package
pkgbuild --root package-root \
         --identifier uk.insoft.$PROJECT_NAME \
         --version 1.0 --install-location / \
         $PROJECT_NAME.pkg
         
productsign --sign "Developer ID Installer: $YOUR_NAME ($TEAM_ID)" $PROJECT_NAME.pkg $PROJECT_NAME-signed.pkg

xcrun notarytool submit --apple-id $APPLE_ID \
                        --password $PASSWORD \
                        --team-id $TEAM_ID \
                        --wait $PROJECT_NAME-signed.pkg
                        
# Staple
xcrun stapler staple $PROJECT_NAME-signed.pkg

# Verify
xcrun stapler validate $PROJECT_NAME-signed.pkg

# Gatekeeper
spctl --assess --type install --verbose $PROJECT_NAME-signed.pkg

rm $PROJECT_NAME.pkg
mv $PROJECT_NAME-signed.pkg ../$PROJECT_NAME\_Xprime\_$(date +"%Y%m%d").pkg
