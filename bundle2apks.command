#!/bin/sh
#set -x
clear
fname=$(basename $0)
moveto=$(dirname $0)
curDir=`pwd`
echo "$curDir => $moveto"
if [ $curDir != moveto ]
then
    cd $moveto
    curDir=$moveto
fi
download_fail(){
    clear
    echo "download fail! Please press command and click to download manually from below link:"
    echo "https://github.com/google/bundletool/releases/download/0.10.2/bundletool-all-0.10.2.jar"
    echo "you can download latest copy from below link:"
    echo "https://github.com/google/bundletool/releases"
    echo "and Please Keep me $fname and bundletool-all-0.10.2.jar together in folder '$curDir' and Try again!"
    #exit
    #closeWindow
}
check_filesize(){
    myfilesize=$(wc -c "./bundletool-all-0.10.2.jar" | awk '{print $1}')
    if [ "$myfilesize" != "38385807" ]
    then
        echo "your file size is $myfilesize, it should be 38385807, so deleting the file"
        rm -fr bundletool-all-0.10.2.jar
        download_fail
    else
        echo "your wait is over!"
    fi
}
count=0
echo "Please wait searching for the App bundle file..."
for foundat in $(find . -name "*.aab" -type f | grep ".aab"); do
count=$(($count+1));
echo "$foundat   ==>$count"
if [ -s "$foundat" ]
then
     echo "The Bundle file found at location: '$foundat' "
     if [ -s "bundletool-all-0.10.2.jar" ]
     then
           check_filesize
           echo "tool is ready to use "
           rm -fr out.apks
           if [ -s "apks" ]
           then
               rm -fr apks/univeral$count/*  apks/splits$count
               echo "clearing old builds from apks/univeral$count/ and apks/splits$count"
           else
               mkdir apks
           fi
           java -jar ./bundletool-all-0.10.2.jar build-apks --bundle=$foundat --output=out.apks --overwrite --mode=universal
           unzip -o out.apks -d apks/univeral$count
           #ls -l apks
           java -jar ./bundletool-all-0.10.2.jar build-apks --bundle=$foundat --output=out.apks --overwrite
           unzip -o out.apks -d apks/splits$count
           #ls -l apks
           rm -fr out.apks
           open apks
           osascript -e 'tell application "Terminal" to close (every window whose name contains ".command")' & exit
     else
           echo "The bundletool-all-0.10.2.jar is missing"
           echo "Please Keep the missing file, $fname script and bundle.aab file here '$curDir'"
           echo "Tool does not exist, Downloading please wait..."
           curl -O https://github.com/google/bundletool/releases/download/0.10.2/bundletool-all-0.10.2.jar
           #curl  https://github.com/google/bundletool/releases/download/0.10.2/bundletool-all-0.10.2.jar
           if [ "$?" != "0" ]
           then
               download_fail
           else
               check_filesize
               echo "Re Run the $fname"
           fi
     fi
else
    echo "please make your app bundle ready first in the '$curDir' or sub-directory of it."
fi
done;
closeWindow() {
    /usr/bin/osascript << _OSACLOSE_
    tell application "Terminal"
        close (every window whose name contains "$fname")
    end tell
    delay 0.3
    tell application "System Events" to click UI element "Close" of sheet 1 of window 1 of application process "Terminal"
_OSACLOSE_
}
#closeWindow
#osascript -e 'tell application "Terminal" to close (every window whose name contains ".command")' & exit
#id=$(echo $$)
#kill -9 $id
#set +x