#!/bin/bash - 
#===============================================================================
#
#          FILE: diy_geexbox.sh
# 
#         USAGE: ./diy_geexbox.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (tangfu), 
#  ORGANIZATION: 
#       CREATED: 2013年04月02日 23时16分30秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#解析参数文件
if [ $# = 1 ];then
    if [ -f $1 ];then
	temp=$1
    else
	echo "diy_geexbox.sh [geexbox_xx.iso]"
	exit 1
    fi
    tmp=${temp##*.}
    if [ ! $tmp = "iso" -a ! $tmp = "ISO" ];then
	echo "diy_geexbox.sh filename must end with \"iso or ISO\""
	exit 1
    fi
    if [ ${temp:0:1} = '/' ];then
	file=$temp
	basefile=${temp##*/}
    elif [ ${temp:0:2} = "./" ];then
	file=`pwd`${temp:1-0}
	basefile=${temp##*/}
    elif [ ${temp:0:3} = "../" ];then
	t=`pwd`
	file=`dirname $t`${temp:2-0}
	basefile=${temp##*/}
    else
	file=`pwd`/$temp
	basefile=$temp
    fi
    newfile=${basefile%.*}_new.iso
#    echo "$file,$newfile"
else
    echo "diy_geexbox.sh [geexbox_xx.iso]"
    exit 1
fi

#建立目录
timestamp=`date +"%s"`
tmp_dir=geexbox_tmp_$timestamp
mkdir $tmp_dir 1>/dev/null

#拷贝原始数据
cd $tmp_dir 1>/dev/null
mkdir iso_ignore
mount -o loop,ro $file iso_ignore 2>/dev/null 1>&2
if [ ! $? = 0 ];then
    echo "mount false"
    exit 1
fi
cp -rf iso_ignore/* .
umount iso_ignore
rm -rf iso_ignore

#解压initrd
cp initrd initrd_bak
mv initrd initrd.xz
unxz initrd.xz
mkdir temp 1>/dev/null
cd temp 1>/dev/null
cpio -i < ../initrd 2>/dev/null 1>&2
rm ../initrd

#修改initrd中的init和busybox
echo -e "modify diy content..."
mv init init_bak
cp ../../diy/init init
mv bin/busybox bin/busybox_bak
cp ../../diy/busybox bin/busybox

#重新打包
echo -e "start package..."
find . | cpio -o -H newc 2>/dev/null | xz -9 --check=crc32 > ../initrd 2>/dev/null
cd ..
mkisofs -J -R -T -v -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -m "*~" -m "*bak" -m "*.swp" -m temp -o ../${newfile} . 2>/dev/null 1>&2

echo -e "\033[36;1mdiy-geexbox succ\033[0m"
