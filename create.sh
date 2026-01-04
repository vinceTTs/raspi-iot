NAME="telegraf"
openssl genrsa -out $NAME.key 2048
openssl req -new -key $NAME.key -out $NAME.csr -subj "/CN=$NAME"
openssl x509 -req -in $NAME.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out $NAME.crt -sha256

