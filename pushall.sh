#!/bin/sh

msg="updateing site $(date)"

git add . 
git commit -m "$msg"

git push origin master
