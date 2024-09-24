echo "Building macos Application";
~/Desktop/Development/flutter/bin/flutter  build macos --no-tree-shake-icons --release

echo "Removing release-build Directory";
rm -r "release-build"

echo "Creating release-build Directory";
mkdir "release-build"

echo "Making Blup.app available for CodeSign";

cp -R "./build/macos/Build/Products/Release/videoapp.app" "release-build/videoapp.app"


cd "release-build/videoapp.app/Contents/"

mkdir -p "assets/mac"

# shellcheck disable=SC2103
cd ..

cd ..

cd ..

cp  "assets/mac/ffmpeg" "release-build/videoapp.app/Contents/assets/mac/"

cd "release-build"

codesign --timestamp  --deep --force --verbose --sign BJ3PK9**** ./videoapp.app

codesign -s BJ3PK9**** -fv --deep --options runtime videoapp.app/Contents/assets/mac/ffmpeg

codesign --sign BJ3PK9****  -fv --deep --options runtime videoapp.app/Contents/MacOS/videoapp
