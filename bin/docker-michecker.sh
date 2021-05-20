#!/bin/bash
/usr/bin/env docker run --rm -v "$PWD":/home -w /home shirasagi/michecker \
  /opt/michecker/bin/michecker --no-sandbox --lang=ja-JP $*
