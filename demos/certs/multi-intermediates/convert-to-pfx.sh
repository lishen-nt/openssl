#!/bin/sh

cat server.pem intca2.pem intca.pem root.pem > cert-chain.pem
openssl pkcs12 -export -keypbe NONE -certpbe NONE -in cert-chain.pem -inkey skey.pem -out cert-chain.pfx
openssl pkcs12 -info -in cert-chain.pfx
base64 cert-chain.pfx > cert-chain.b64