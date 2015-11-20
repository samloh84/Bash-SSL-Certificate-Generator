#!/bin/bash -xe

export DIR=`pwd`
export ROOT_CA_DIR="${DIR}/root-ca"

export OPENSSL_CONF="${DIR}/root-ca.cnf"

export ROOT_CA_CERT_BASENAME="${ROOT_CA_DIR}/root-ca-cert"
export ROOT_CA_KEY_PEM="${ROOT_CA_DIR}/private/root-ca-key.pem"
export ROOT_CA_CERT_PEM="${ROOT_CA_CERT_BASENAME}.pem"
export ROOT_CA_CERT_CRT="${ROOT_CA_CERT_BASENAME}.crt"
export ROOT_CA_CERT_PKCS12="${ROOT_CA_CERT_BASENAME}.p12"
export ROOT_CA_CERT_JKS="${ROOT_CA_CERT_BASENAME}.jks"

export PASSPHRASE=Pass1234

if [ ! -d  "${ROOT_CA_DIR}/private" ]; then
    mkdir -p "${ROOT_CA_DIR}/private"
fi

if [ ! -d  "${ROOT_CA_DIR}/certs" ]; then
    mkdir -p "${ROOT_CA_DIR}/certs"
fi

if [ ! -f "${ROOT_CA_DIR}/serial" ]; then
    echo '01' > "${ROOT_CA_DIR}/serial"
fi

if [ ! -f "${ROOT_CA_DIR}/index.txt" ]; then
    touch "${ROOT_CA_DIR}/index.txt"
fi

if [ ! -f "${ROOT_CA_CERT_PEM}" -a ! -f "${ROOT_CA_KEY_PEM}" ]; then
    echo "Generating Certificate Authority Certificate and Key"
    openssl req -x509 -newkey rsa:4096 -out "${ROOT_CA_CERT_PEM}" -outform PEM
fi

if [ -f "${ROOT_CA_CERT_PEM}" -a ! -f "${ROOT_CA_CERT_CRT}" ]; then
	echo "Exporting Certificate Authority Certificate"
	openssl x509 -in "${ROOT_CA_CERT_PEM}" -out "${ROOT_CA_CERT_CRT}"
fi

if [ -f "${ROOT_CA_CERT_PEM}" -a ! -f "${ROOT_CA_CERT_JKS}" ]; then
	echo "Generating Java Truststore"
	keytool -import -file "${ROOT_CA_CERT_PEM}" -keystore "${ROOT_CA_CERT_JKS}" -storepass ${PASSPHRASE} -alias 0 -noprompt
fi
