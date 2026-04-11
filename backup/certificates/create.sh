#!/bin/bash

# Prüfen, ob ein Name übergeben wurde
if [ -z "$1" ]; then
  echo "Usage: $0 <NAME>"
  exit 1
fi

NAME="$1"

echo "Erzeuge Zertifikat für: $NAME"

# Private Key
openssl genrsa -out "$NAME.key" 2048

# CSR
openssl req -new -key "$NAME.key" -out "$NAME.csr" -subj "/CN=$NAME"

# Signiertes Zertifikat
openssl x509 -req -in "$NAME.csr" -CA ca.crt -CAkey ca.key -CAcreateserial -out "$NAME.crt" -sha256

echo "Fertig:"
echo "  $NAME.key"
echo "  $NAME.csr"
echo "  $NAME.crt"
