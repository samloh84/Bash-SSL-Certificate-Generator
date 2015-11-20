#!/bin/bash -xe

export DIR=`pwd`

export FILES="${DIR}"/*.cnf

export PASSPHRASE=Pass1234
export ROOT_CA_CERT_PEM="${DIR}/root-ca/root-ca-cert.pem"

for f in ${FILES}; do

    filename=$(basename "$f" .cnf)

    if [ "$filename" = "root-ca" ]; then
        continue
    fi
       	
	export CERT_BASENAME="${DIR}/${filename}_cert"
	export KEY_PEM="${DIR}/${filename}_key.pem"
	export CERT_PEM="${CERT_BASENAME}.pem"
	export CERT_CRT="${CERT_BASENAME}.crt"
	export CERT_PKCS12="${CERT_BASENAME}.p12"
	export CERT_JKS="${CERT_BASENAME}.jks"

    if [ ! -f "${CERT_PEM}" -a ! -f "${KEY_PEM}" ]; then
        export OPENSSL_CONF="${DIR}/${filename}.cnf"
        export TEMP_KEY_PEM="${DIR}/temp_key.pem"
        export TEMP_REQ_PEM="${DIR}/temp_req.pem"
        export TEMP_CERT_PEM="${DIR}/temp_cert.pem"

        echo "Generating Server Certificate Signing Request and Key"
        openssl req -newkey rsa:4096 -keyout "${TEMP_KEY_PEM}" -keyform PEM -out "${TEMP_REQ_PEM}" -outform PEM

        echo "Exporting Server Key"
        openssl rsa < "${TEMP_KEY_PEM}" > "${KEY_PEM}" -passin pass:${PASSPHRASE}

        export OPENSSL_CONF="${DIR}/root-ca.cnf"

        echo "Signing Server Certificate"
        openssl ca -in "${TEMP_REQ_PEM}" -out "${CERT_PEM}" -passin pass:${PASSPHRASE} -batch

        rm -f "${TEMP_KEY_PEM}" && rm -f "${TEMP_REQ_PEM}"
    fi

	if [ -f "${CERT_PEM}" -a ! -f "${CERT_CRT}" ]; then
        echo "Exporting Server Certificate"
        openssl x509 -in "${CERT_PEM}" -out "${CERT_CRT}" -passin pass:${PASSPHRASE}
	fi


    if [ -f "${CERT_PEM}" -a -f "${KEY_PEM}" -a ! -f "${CERT_PKCS12}" ]; then
        echo "Generating PKCS12 Keystore"
        openssl pkcs12 -export -in "${CERT_PEM}" -inkey "${KEY_PEM}" -passout pass:${PASSPHRASE} -CAfile "${ROOT_CA_CERT_PEM}" -chain -name 0 -out "${CERT_PKCS12}"
    fi

    if [ -f "${CERT_PKCS12}" -a ! -f "${CERT_JKS}" ]; then
        echo "Generating Java Keystore"
        keytool -importkeystore -srcstoretype pkcs12 -srckeystore "${CERT_PKCS12}" -srcstorepass ${PASSPHRASE} -srcalias 0 -destkeystore "${CERT_JKS}" -deststorepass ${PASSPHRASE} -destalias 0 -noprompt
    fi
done
