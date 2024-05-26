#!/usr/bin/env bash

if [ ! -d "crates" ]; then
  curl -L https://github.com/roc-lang/roc/releases/download/nightly/roc_nightly-linux_x86_64-latest.tar.gz -o roc_nightly.tar.gz
  tar -xzvf roc_nightly.tar.gz
  rm -rf roc_nightly.tar.gz
  mv roc_nightly* roc_nightly
  cp -r roc_nightly/crates/ crates/
  cp roc_nightly/roc roc
fi