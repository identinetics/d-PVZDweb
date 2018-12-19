#!/bin/bash -e

httpcode=$(curl -s -o /dev/null -w "%{http_code}\n" 'http://localhost:8080/admin/')
if [[ "$httpcode" == '302' ]]; then
    echo 'Django admin app OK'
else
    echo "unexpected return code from Django admin app. HTTP code=" $httpcode
    exit 1
fi
