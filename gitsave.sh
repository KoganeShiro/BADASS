#/bin/sh
now=$(date)
echo $now\n
git add .
git commit -m "save $now"
git push

