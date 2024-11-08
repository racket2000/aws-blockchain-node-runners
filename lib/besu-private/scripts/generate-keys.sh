#!/bin/bash
source .env

if [[ -z $NUM_VALIDATORS ]]; then
    echo "NUM_VALIDATORS $NUM_VALIDATORS is not set. Did you set .env?"
    exit 1
fi

if [[ -z "${SHARD}" ]]; then
    echo "SHARD is not set. Did you set .env?"
    exit 1
fi

if [[ -z "${FIRST_DEPLOY}" ]]; then
    echo "FIRST_DEPLOY is not set. Do not run this script on existing networks."
    exit 1
fi

echo "*** This is a helper script meant to be run on a brand new private network ONLY."
echo "*** By pressing [Enter] you acknowledge that any previously deployed ECC keys may be overwritten,"
echo "*** rendering any existing or previously deployed private networks launched through this CDK inoperable.";
read line

for i in $(seq 1 $NUM_VALIDATORS);
do
    let "j = $i - 1"
    echo "Generating Keys for Validator $j"
    aws kms generate-data-key-pair --key-pair-spec ECC_SECG_P256K1 --key-id alias/PrivateChainEbsVolumeEncryptionKey | jq '[.PublicKey, .PrivateKeyPlaintext]' > tmp.txt
    cat tmp.txt | jq -r '"\"" + .[0] + "\","' >> pubkeys.txt
    cat tmp.txt | jq -r '.[1]' | aws secretsmanager put-secret-value --secret-id "Shard-$SHARD-ValidatorSignKey-$j" --secret-string $(< /dev/stdin)
    sleep 1
done
PUBKEY_FILE="./lib/constants/keys.ts"
echo "// This file was autogenerated by generate-keys.sh" > $PUBKEY_FILE
echo "// These should be DER-encoded X.509 public keys in Base64." >> $PUBKEY_FILE
echo 'export const PUBLIC_KEYS_BASE64 = [' >> $PUBKEY_FILE
cat pubkeys.txt >> $PUBKEY_FILE
echo ']' >> $PUBKEY_FILE
rm tmp.txt
rm pubkeys.txt

echo "Done. See lib/constants/keys.ts for the generated public keys.";