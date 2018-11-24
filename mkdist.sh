#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Error: no version supplied."
	echo "Usage: mkdist.sh version"
	exit 1
fi

zip="/c/Program Files/7-Zip/7z.exe"

prefix="yam-of-endor"
name="$prefix-$1"
mac="$name.app"
win="$name-win"
win32="$name-win32"

rm -f "dist/$name.love"
"$zip" a -tzip -mx9 "dist/$name.love" @MANIFEST

cp -r ../love-versions/win64 "dist/$win"
cp -r ../love-versions/win32 "dist/$win32"
cp -r ../love-versions/osx "dist/$mac"

cp LICENSE.txt README.md screenshot.jpg "dist/$win"
cp LICENSE.txt README.md screenshot.jpg "dist/$win32"
cp LICENSE.txt README.md screenshot.jpg "dist/$mac"

cat "dist/$win/love.exe" "dist/$name.love" >"dist/$win/$name.exe"
rm "dist/$win/love.exe"

cat "dist/$win32/love.exe" "dist/$name.love" >"dist/$win32/$name.exe"
rm "dist/$win32/love.exe"

sed -e "s/GAME_URL_HERE/com.qualdan.yam-of-endor/;s/GAME_NAME_HERE/Yam of Endor/" "../love-versions/Info.plist" >"dist/$mac/Contents/Info.plist"
cp "dist/$name.love" "dist/$mac/Contents/Resources/"

cd dist

rm -f "$win.zip"
rm -f "$win32.zip"
rm -f "$mac.zip"

"$zip" a -tzip -mx9 "$win.zip" "$win"
"$zip" a -tzip -mx9 "$win32.zip" "$win32"
"$zip" a -tzip -mx9 "$mac.zip" "$mac"

rm -rf "$win"
rm -rf "$win32"
rm -rf "$mac"
