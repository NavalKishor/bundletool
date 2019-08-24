#!/bin/sh
#set -x
clear
Android_Home=~/Library/Android/sdk
buildToolVer=$(ls -1  $Android_Home/build-tools/ | tail -1)
Android_Home=$Android_Home:$Android_Home/tools:$Android_Home/platform-tools:$Android_Home/build-tools/$buildToolVer/
export PATH=$PATH:$Android_Home
echo "pass argument 1=make apk for connected device and install on device"
echo "pass argument 2=install universal apk to connected device"
install=$1
connectedDeviceOnly=1
universalApk=2
fname=$(basename $0)
moveto=$(dirname $0)
curDir=`pwd`
#echo "Your in the $curDir :moving to=> $moveto"
if [ $curDir != moveto ]
then
    cd $moveto
    curDir=$moveto
fi
replace(){
local str=$1
str=${str//\'/$''}
echo $str
}
appDetail()
{
apkname=$(basename $2)
apkname=${apkname:0:${#apkname}-4}
#echo "Apks of the bundle at path $2" > $3/app$1.txt
launchActivity=$(aapt dump badging $4 | grep -i launchable-activity | cut -d =  -f 2 | cut -d ' ' -f 1)
launchActivity=$(replace $launchActivity)
pn=$(aapt dump badging $4 | grep -i versionCode | cut -d =  -f 2 | cut -d ' ' -f 1)
pn=$(replace $pn)
local vc=$(aapt dump badging $4 | grep -i versionCode | cut -d =  -f 3 | cut -d ' ' -f 1)
vc=$(replace $vc)
local vn=$(aapt dump badging $4 | grep -i versionName | cut -d =  -f 4 | cut -d ' ' -f 1)
vn=$(replace $vn)
apknames="["
for i in $(ls -1 $(dirname $4));do
    if [ ${i##*.} == apk ]
    then
        #mv $4 $3/$apkname.apk
        apknames=$apknames$i,
        #echo $apknames
    fi
done;
apknames=${apknames:0:${#apknames}-1}"]"
echo "ListOfApkToInstall:$apknames"
cat <<EOM >$3/output$1.txt
[{"outputType":{"type":"APK"},"apkData":{"type":"MAIN","packageName":$pn,"versionCode":$vc,"versionName":"$vn","enabled":true,"outputApkFiles":$apknames,"createdAppName":"$(basename $4)","yourAppName":"$apkname"},"inputPath":"$2","outPath":"$(dirname $4)","properties":{}}]
EOM
}
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
locToFind=$(dirname $(pwd))
echo "i am looking here:"$locToFind
echo "Please wait searching for the App bundle file..."
for foundat in $(find $locToFind -name "*.aab" -type f | grep ".aab"); do
if [[ $foundat = *"/build/intermediates/intermediary_bundle/"* ]]
then
    continue
fi
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
               rm -fr apks/univeral$count/*  apks/splits$count apks/device$count
               echo "clearing old builds from apks/univeral$count/ and apks/splits$count apks/device$count"
           else
               mkdir apks
           fi
           if [ "$install" = "$connectedDeviceOnly" ]
           then
               java -jar ./bundletool-all-0.10.2.jar build-apks --bundle=$foundat --output=out.apks --overwrite --connected-device --ks=../debug.keystore --ks-pass="pass:android" --ks-key-alias="AndroidDebugKey" --key-pass="pass:android" 2>/dev/null
               unzip -o out.apks -d apks/device$count 2>/dev/null
               appDetail $count $foundat ./apks/device$count ./apks/device$count/splits/base-master.apk
               java -jar ./bundletool-all-0.10.2.jar install-apks --apks=out.apks 2>/dev/null
               status=$?
               if [ $status != 0 ]
               then
                    adb install-multiple -r -t -g apks/device$count/splits/*.apk 2>/dev/null
                    if [ "$?" = "0" ]
                    then
                        adb shell am start -n "$pn/$launchActivity" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
                    fi
               else
                    adb shell am start -n "$pn/$launchActivity" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
               fi
           fi
           java -jar ./bundletool-all-0.10.2.jar build-apks --bundle=$foundat --output=out.apks --overwrite --mode=universal --ks=../debug.keystore --ks-pass="pass:android" --ks-key-alias="AndroidDebugKey" --key-pass="pass:android"
           unzip -o out.apks -d apks/universal$count
           #apksigner sign --ks ../debug.keystore --out ./apks/universal$count/universal_debug_sign.apk ./apks/universal$count/universal.apk
           appDetail $count $foundat ./apks/universal$count ./apks/universal$count/universal.apk
           open apks/universal$count
           if [ "$install" = "$universalApk" ]
           then
               adb install -r -f -g apks/universal$count/universal.apk 2>/dev/null
               adb shell am start -n "$pn/$launchActivity" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
           fi
           #ls -l apks
           java -jar ./bundletool-all-0.10.2.jar build-apks --bundle=$foundat --output=out.apks --overwrite --ks=../debug.keystore --ks-pass="pass:android" --ks-key-alias="AndroidDebugKey" --key-pass="pass:android"
           unzip -o out.apks -d apks/splits$count
           appDetail $count $foundat ./apks/splits$count ./apks/splits$count/splits/base-master.apk
           #ls -l apks
           rm -fr out.apks
           #open apks
           #osascript -e 'tell application "Terminal" to close (every window whose name contains ".command")' & exit
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
open apks
echo "i am done, Thanks for giving a try! :)"
#closeWindow
osascript -e 'tell application "Terminal" to close (every window whose name contains ".command")' & exit
#id=$(echo $$)
#kill -9 $id
#set +x