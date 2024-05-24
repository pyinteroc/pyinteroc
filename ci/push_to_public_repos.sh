#!/usr/bin/env bash

### This assumes we are working in the trunk branch

### Deploy to origin first
git pull origin master
git push origin master

### deploy to github
git push github main
