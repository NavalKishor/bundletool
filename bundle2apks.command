#!/bin/sh
#set -x
clear
#install="-1"
usage(){
    echo "Usage: $0 [-i] [-d] [-p] [-a] [-k] [-?] [-h]"
    echo "-i : to install the apks \n\tpass 1 for connected devices and \n\tpass 2 for the universal apks"
    echo "-d : to pass keystore password"
    echo "-p : to pass keystore key Alias name"
    echo "-p : to pass key password"
    echo "-h : to get help"
    echo "-? : to get help"
}
#echo "pass argument 1=make apk for connected device and install on device."
#echo "pass argument 2=install universal apk to connected device."
#usage
while getopts i:d:p:a:k:?h arg
do
    case $arg in
        i)  install=$OPTARG
            ;;
        d)  debugKeyStore=$OPTARG
            ;;
        p)  pass=pass:$OPTARG
            ;;
        a)  ksKeyAlias=$OPTARG
            ;;
        k)  keyPass=pass:$OPTARG
            ;;
        :)  echo "Invalid option: $OPTARG requires an argument" 1>&2
            ;;
        h|? ) usage
              exit 2
            ;;
        *)  echo "Hmm, seems i've never used it.$OPTARG"
            ;;
    esac
done
if [ ! -f "$debugKeyStore" ];then
    echo "The file '$debugKeyStore' does not exist";
    unset debugKeyStore
    echo $debugKeyStore":unset"
fi
#echo "{$#,install:$install\ndebugKeyStore:$debugKeyStore\npass:$pass\nksKeyAlias:$ksKeyAlias\nkeyPass:$keyPass\ninProject:$inProject\n[$1,$2,$3,$4,$5,$6,$7,$8,$9]\n\$@:[$@]}"
Android_Home=~/Library/Android/sdk
buildToolVer=$(ls -1  $Android_Home/build-tools/ | tail -1)
Android_Home=$Android_Home:$Android_Home/tools:$Android_Home/platform-tools:$Android_Home/build-tools/$buildToolVer/
export PATH=$PATH:$Android_Home
if [ $# -le 7 -o -z "$debugKeyStore" -o -z "$pass" -o -z "$ksKeyAlias" -o -z "$keyPass" ]
then
    #echo "no argument $2"
    debugKeyStore=$(ls  ~/.android/debug.keystore)
    pass="pass:android"
    ksKeyAlias="AndroidDebugKey"
    keyPass="pass:android"
    inProject=$(ls ../debug.keystore)
    if [ ! -z $inProject ];then
        debugKeyStore="$inProject"
    fi
fi
install="${install:-$1}"
connectedDeviceOnly=1
universalApk=2
#echo "[$install]\n$debugKeyStore\n$pass\n$ksKeyAlias\n$keyPass\n$inProject\n[$1,$2,$3,$4,$5,$6,$7,$8,$9]$@"
#exit
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
lsDir=$(ls -1 $(dirname $4))
dirOfApk=$(dirname $4)
apkTypeName=$(basename $(dirname $2))
apknames="["
for i in $lsDir;do
    if [ ${i##*.} == apk ]
    then
        if [ "app" != "$apkname" ]; then
            cp $dirOfApk/$i $dirOfApk/$apkTypeName$apkname-$vc-$i
            apknames=$apknames$apkTypeName$apkname-$vc-$i,
        else
            apknames=$apknames$i,
        fi
    fi
done;
apknames=${apknames:0:${#apknames}-1}"]"
echo "ListOfApkToInstall:$apknames"
cat <<EOM >$3/output$1.txt
[{"outputType":{"type":"APK"},"apkData":{"type":"MAIN","packageName":$pn,"versionCode":$vc,"versionName":"$vn","enabled":true,"outputApkFiles":$apknames,"createdAppName":"$(basename $4)","yourAppName":"$apkname","Time":$(date +"%Y-%m-%d %T")},"inputPath":"$2","outPath":"$(dirname $4)","properties":{}}]
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
               rm -fr apks/universal$count/*  apks/splits$count/*  apks/device$count/*
               echo "clearing old builds from apks/univeral$count/ and apks/splits$count apks/device$count"
           else
               mkdir apks
           fi
           if [ "$install" = "$connectedDeviceOnly" ]
           then
               java -jar ./bundletool-all-0.10.2.jar build-apks --bundle=$foundat --output=out.apks --overwrite --connected-device --ks=$debugKeyStore --ks-pass="$pass" --ks-key-alias="$ksKeyAlias" --key-pass="$keyPass" 2>/dev/null
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
           java -jar ./bundletool-all-0.10.2.jar build-apks --bundle=$foundat --output=out.apks --overwrite --mode=universal --ks=$debugKeyStore --ks-pass="$pass" --ks-key-alias="$ksKeyAlias" --key-pass="$keyPass"
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
           java -jar ./bundletool-all-0.10.2.jar build-apks --bundle=$foundat --output=out.apks --overwrite --ks=$debugKeyStore --ks-pass="$pass" --ks-key-alias="$ksKeyAlias" --key-pass="$keyPass"
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