#!/bin/sh

# Recreate the demo certificates in the apps directory.

OPENSSL=openssl

rm *.pem
rm *.srl

$OPENSSL genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out rootkey.pem
$OPENSSL genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out intkey.pem
$OPENSSL genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out intkey2.pem
$OPENSSL genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out skey.pem
$OPENSSL genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out skey2.pem
$OPENSSL genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out ckey.pem

# Root CA: create certificate directly
CN="OpenSSL Test Root CA" $OPENSSL req -config apps.cnf -x509 -nodes \
	-keyout root.pem -out root.pem -key rootkey.pem -new -days 3650
# Intermediate CA: request first
CN="OpenSSL Test Intermediate CA" $OPENSSL req -config apps.cnf -nodes \
	-key intkey.pem -out intreq.pem -new
# Sign request: CA extensions
$OPENSSL x509 -req -in intreq.pem -CA root.pem -CAkey rootkey.pem -days 3630 \
	-extfile apps.cnf -extensions v3_ca -CAcreateserial -out intca.pem

# Intermediate CA2: request first
CN="OpenSSL Test Intermediate CA 2" $OPENSSL req -config apps.cnf -nodes \
	-key intkey2.pem -out intreq2.pem -new
# Sign request: CA extensions
$OPENSSL x509 -req -in intreq2.pem -CA root.pem -CAkey rootkey.pem -days 3610 \
	-extfile apps.cnf -extensions v3_ca -CAcreateserial -out intca2.pem

# Client certificate: request first
CN="Test Client Cert" $OPENSSL req -config apps.cnf -nodes \
	-key ckey.pem -out creq.pem -new
# Sign using intermediate CA
$OPENSSL x509 -req -in creq.pem -CA intca2.pem -CAkey intkey2.pem -days 3600 \
	-extfile apps.cnf -extensions usr_cert -CAcreateserial | \
	$OPENSSL x509 -nameopt oneline -subject -issuer >client.pem
# Server certificate: request first
CN="Test Server Cert" $OPENSSL req -config apps.cnf -nodes \
	-key skey.pem -out sreq.pem -new
# Sign using intermediate CA
$OPENSSL x509 -req -in sreq.pem -CA intca2.pem -CAkey intkey2.pem -days 3600 \
	-extfile apps.cnf -extensions usr_cert -CAcreateserial | \
	$OPENSSL x509 -nameopt oneline -subject -issuer >server.pem
# Server certificate #2: request first
CN="Test Server Cert #2" $OPENSSL req -config apps.cnf -nodes \
	-key skey2.pem -out sreq2.pem -new
# Sign using intermediate CA
$OPENSSL x509 -req -in sreq2.pem -CA intca2.pem -CAkey intkey2.pem -days 3600 \
	-extfile apps.cnf -extensions usr_cert -CAcreateserial | \
	$OPENSSL x509 -nameopt oneline -subject -issuer >server2.pem

# Append keys to file.

cat skey.pem >>server.pem
cat skey2.pem >>server2.pem
cat ckey.pem >>client.pem

$OPENSSL verify -CAfile root.pem -untrusted intca.pem -untrusted intca2.pem\
				server2.pem server.pem client.pem
