#!/bin/sh -e

function patch_file() {
  perl -p -e "$2" "$1" > "$1~"
  mv -f "$1~" "$1"
}
 
if [ $# -ne 2 ]; then
  echo "`basename $0` AppName BundleID"
  exit 1
fi
PRODUCT_NAME="$1"
PROJECT_NAME=`echo "$1" | tr -d ' '`
BUNDLE_ID="$2"

echo "Product Name: '$PRODUCT_NAME'"
echo "Project Name: '$PROJECT_NAME'"
echo "Bundle ID: '$BUNDLE_ID'"
read -p "Continue [y/N]? " yn
if [ "$yn" != "y" ]; then
  exit 1
fi
set -x

pushd "InAppStore"
git fetch
git pull
popd

pushd "MixpanelTracker"
git fetch
git pull
popd

pushd "Resources/en.lproj"
patch_file "Localizable.strings" "s/Xcode App Template/$PRODUCT_NAME/g"
patch_file "MainMenu.xib" "s/Xcode App Template/$PRODUCT_NAME/g"
popd

pushd "XcodeAppTemplate.xcodeproj"
patch_file "project.pbxproj" "s/Xcode App Template/$PRODUCT_NAME/g;s/XcodeAppTemplate/$PROJECT_NAME/g;s/net.pol-online.xcode-app-template/$BUNDLE_ID/g"
rm -rf "project.xcworkspace"
rm -rf "xcshareddata"
rm -rf "xcuserdata"
popd
mv "XcodeAppTemplate.xcodeproj" "$PROJECT_NAME.xcodeproj"

rm -f "$0"
echo "Done!"
