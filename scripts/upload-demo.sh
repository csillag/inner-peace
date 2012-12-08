#!/bin/sh
cd /tmp
rm -rf inner-peace
git clone https://github.com/csillag/inner-peace.git
cd inner-peace/app
s3cmd --delete-removed sync . s3://inner-peace-demo/
