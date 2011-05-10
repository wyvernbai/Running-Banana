#!/bin/bash
#Program:
#      Get the information from today.hit.edu.cn
#TIP:
#      功能         同步today.hit.edu.cn RSS内容。
#      使用         本脚本可在任意目录下运行，如果默认的localserver地址不是/var/www，请自行修改，
#                   MAX的值确定最多可存储的新闻数目。
#                   客户器端获取info内容，得到start节点以及end节点。
#                   新闻文件夹以环形队列的形式顺次每半小时更新一次，自动匹配发布时间，防止新闻重
#                   复，同时保持最旧的新闻排在最前，最新的新闻排在最后。
#History:
#      2011/03/08    wyvern.bai@gmail.com

#MAX决定服务器端最大能保存的新闻数目
MAX=100

overflow=0
#服务器路径
localserver="/var/www/iHIT"

#获取终止节点
startnode=`cat $localserver/info | sed -n 's/.*\^\([|0-9]\{1,\}\)\^.*$/\1/p'`

#获取起始节点
endnode=`cat $localserver/info | sed -n 's/.*\^\([-|0-9]\{1,\}\)$/\1/p'`

#最后一则新闻的时间
lasttime=`cat $localserver/info | sed -n 's/^\([0-9]\{1,\}\)\^.*$/\1/p'`

let endnode=endnode+1
let endnode=endnode%MAX

echo "startnode: $startnode"
echo "(endnode+1)%MAX: $endnode"
echo "last news's time: $lasttime"

#for((i=0;i<MAX;i++))
#do
    #创建MAX个文件夹,用来记录MAX条新闻
#    mkdir $localserver/$i
#done

mainurl="http://today.hit.edu.cn"
url="http://today.hit.edu.cn/rss.xml"

wget -nv -O lala.xml "$url"
iconv --from-code=gb18030 --to-code=UTF-8 lala.xml > lala_temp.xml
#vim -c "argdo se bomb |  set fileencoding=utf-8 | wq" lala.xml
cat lala_temp.xml | sed -e 's/<?xml version=\"1.0\" encoding=\"gb2312\"?>/<?xml version=\"1.0\" encoding=\"utf-8\"?>/g' > lala.xml
xmllint --format lala.xml > rss.xml

cat rss.xml | sed -n '7,$p' | sed -e 's/<span[^>]*>//g' -e 's/<\/span>//g' \
    -e 's/<p[^>]*>//g' -e 's/<\/p>//g' -e 's/<div[^>]*>//g' -e 's/<\/div>//g' -e 's/<strong>//g' \
    -e 's/<\/strong>//g' -e 's/<u>//g' -e 's/<\/u>//g' -e 's/<b>//g' -e 's/<\/b>//g' -e 's/<a [^>]*>//g' \
    -e 's/<\/a>//g' -e 's/<font[^>]*>//g' -e 's/<\/font>//g' -e 's/<o:p>//g' -e 's/<\/o:p>//g' \
    -e 's/<b[^>]*>//g' -e 's/<\/b>//g'> rss.temp
tac rss.temp > rss.xml

cat rss.xml | grep -E '<description>' | sed -e 's/[ ]*<description><!\[CDATA\[//g' \
    > description.all

cat rss.xml | grep -E '<\/pubDate>' | \
    sed -e 's/Jan/01/g' -e 's/Feb/02/g' -e 's/Mar/03/g'  -e 's/Apr/04/g' -e 's/May/05/g' -e 's/Jun/06/g' \
    -e 's/Jul/07/g' -e 's/Aug/08/g' -e 's/Sep/09/g' -e 's/Oct/10/g' -e 's/Nov/11/g' -e 's/Dec/12/g' > pubDate.all

cat rss.xml | grep -E '<title>' | \
    sed -e 's/^[ ]*//' -e 's/<title><!\[CDATA\[//g' -e 's/\]\]><\/title>//g' \
    -e 's/&amp;/\&/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&middot;/·/g' \
    -e 's/&ensp;/ /g' -e 's/&emsp;/ /g' -e 's/&times;/×/g' -e 's/&divide;/÷/g' -e 's/&mdash;/—/g' \
    -e 's/&lsquo;/‘/g' -e 's/&rsquo;/’/g' -e 's/&sbquo;/‚/g' -e 's/&bdquo;/„/g' -e 's/&hellip;/…/g' \
    -e 's/&quot;/\"/g' -e 's/&ldquo;/“/g' -e 's/&rdquo;/”/g' -e 's/&nbsp;//g' -e "s/&apos/'/g" \
    -e 's/&lt;/</g' -e 's/&gt;/>/g'  > title.all

cat rss.xml | grep -E '<link>' | \
    sed -e 's/<link><!\[CDATA\[//g' -e 's/\]\]><\/link>//g' -e 's/[ ]*//g'> link.all

cat rss.xml | grep -E '<author>'|
sed -e 's/<author><!\[CDATA\[//g' -e 's/\]\]><\/author>//g' -e 's/[ ]*//g'> author.all

#RSS中包含的新闻数目
lnnum=`sed -n '$=' description.all`
#echo $lnnum

for((i=0;i<lnnum;i++))
do
    #获取时间并将其提取、拼接成数字
    pubdate_year=`sed -n ''$(($i+1))'p' pubDate.all | sed -n 's/.* \([0-9]\{1,\}\) \([0-9]\{2,\}\):.*$/\1/p'`
    pubdate_month=`sed -n ''$(($i+1))'p' pubDate.all | sed -n 's/.*, \([0-9]\{1,\}\) \([0-9]\{2,\}\) .*$/\2/p'`
    pubdate_day=`sed -n ''$(($i+1))'p' pubDate.all | sed -n 's/.*, \([0-9]\{1,\}\) \([0-9]\{2,\}\) .*$/\1/p'`
    pubdate_hour=`sed -n ''$(($i+1))'p' pubDate.all | sed -n 's/.* \([0-9]\{1,\}\) \([0-9]\{2,\}\):.*$/\2/p'`
    pubdate_minute=`sed -n ''$(($i+1))'p' pubDate.all | sed -n 's/.*:\([0-9]\{1,\}\):\([0-9]\{2,\}\).*$/\1/p'`
    pubdate_second=`sed -n ''$(($i+1))'p' pubDate.all | sed -n 's/.*:\([0-9]\{1,\}\):\([0-9]\{2,\}\).*$/\2/p'`
    pubdate_all[$i]="${pubdate_year}${pubdate_month}${pubdate_day}${pubdate_hour}${pubdate_minute}${pubdate_second}"

    #将当前新闻时间为上次更新的最新新闻的时间做比较，如果当前新闻时间比lasttime新，则更新新闻
    if [ ${pubdate_all[$i]} -gt $lasttime ]; then
        rm -rf $localserver/$endnode
        mkdir $localserver/$endnode

        #提取图片
        jpgurl[$i]=`sed -n ''$(($i+1))'p' description.all | sed -n "s/.*<img[^>]*src=[\"]\([.|0-9|A-Z|a-z|/|:|-]\{1,\}\)[\"] \/>.*$/\1/p"`
        #没有图片
        if [ -z ${jpgurl[$i]} ]; then
            echo "Node $endnode NO image"
        else
            wget -nv -O $localserver/$endnode/$endnode.jpg "$mainurl${jpgurl[$i]}"
            convert $localserver/$endnode/$endnode.jpg -resize 100x100^ \
                -gravity center -extent 100x100 $localserver/$endnode/$endnode.thumb
            convert $localserver/$endnode/$endnode.jpg -resize 280x140^ \
                -gravity center -extent 280x140 $localserver/$endnode/$endnode.img
	    echo "Node $endnode image converted!"
        fi

        #服务器端生成文件
        sed -n ''$(($i+1))'p' description.all  |  sed  -e 's/<img.*<\/description>$//g'  -e 's/\.\.\.\]\]><\/description>//g'  \
            -e 's/\]\]><\/description>//g' -e 's/[ ]*<table[^>]*>[ ]*//g' -e 's/<st1[^>]*>//g' \
            -e 's/<\/st1[^>]*>//g'  -e 's/[ ]*<\/table>[ ]*//g' \
            -e 's/[ ]*<tbody[^>]*>[ ]*/\n/g' -e 's/[ ]*<\/tbody>[ ]*/\n/g' -e 's/[ ]*<tr[^>]*>[ ]*/\n/g' \
            -e 's/[ ]*<\/tr>[ ]*//g' -e 's/[ ]*<td[^>]*>[ ]*//g' -e 's/[ ]*<\/td>[ ]*/\t/g' \
            -e 's/<\/i>//g' -e 's/<i[^>]*>//g' | sed  -e 's/&amp;/\&/g' \
            -e 's/&quot;/\"/g' -e 's/&ldquo;/“/g' -e 's/&rdquo;/”/g' -e 's/&nbsp;/ /g' -e "s/&apos/'/g" \
            -e 's/&middot;/·/g' -e 's/&ensp;/ /g' -e 's/&emsp;/ /g' -e 's/&times;/×/g' -e 's/&divide;/÷/g' \
            -e 's/&mdash;/—/g' -e 's/&lsquo;/‘/g' -e 's/&rsquo;/’/g' -e 's/&sbquo;/‚/g' -e 's/&bdquo;/„/g' \
            -e 's/&hellip;/…/g' -e 's/&sup2;//g'  -e 's/<br \/>/\n/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' >  $localserver/$endnode/$endnode.description
        sed -n ''$(($i+1))'p' title.all | sed -e 's/<title>//g' -e 's/<\/title>//g' >  $localserver/$endnode/$endnode.title
        sed -n ''$(($i+1))'p' link.all > $localserver/$endnode/$endnode.link
	echo "${pubdate_all[$i]}" > $localserver/$endnode/$endnode.num
        Newstimeout="${pubdate_year}年${pubdate_month}月${pubdate_day}日 ${pubdate_hour}:${pubdate_minute}"
        authorname=`sed -n ''$(($i+1))'p' author.all`
        echo "$Newstimeout $authorname" > $localserver/$endnode/$endnode.time
	
        #建立环状列表，循环更新
        let endnode=endnode+1
        let endnode=endnode%MAX
        if [ $endnode -eq $startnode ]; then
            let startnode=startnode+1
            let startnode=startnode%MAX
        fi
    fi

done
lasttime=${pubdate_all[$(($lnnum-1))]}

#将最新新闻的时间，环状列表的头节点，尾节点写入info。客户端只需要先获取info信息，
#然后按顺序更新头节点和尾节点之间的新闻即可
if [ $endnode -eq $overflow ]; then
	echo "$lasttime^$startnode^$(($MAX-1))" > $localserver/info
else
	echo "$lasttime^$startnode^$(($endnode-1))" > $localserver/info
fi
