#!/bin/bash
set -e
set -o pipefail
export DOLLAR='$'
envsubst < /config.template.conf > /etc/nginx/conf.d/default.conf

cert_path="/etc/letsencrypt/live/${NGINX_HOST}"
mkdir -p "${cert_path}"
if [ ! -s "${cert_path}/fullchain.pem" ] && [ ! -f "${cert_path}/real" ]; then
    openssl req -x509 -nodes -days 2 -newkey rsa:2048 \
        -keyout "${cert_path}/privkey.pem" -out "${cert_path}/fullchain.pem" \
        -subj "/C=DE/ST=Somewhere/L=/O=/OU=temp cert/CN=${NGINX_HOST}"
fi

nginx -g "daemon off;" &

(set -e
    if [ ! -f "${cert_path}/real" ]; then
        sleep 10
        echo "requesting new certificate"
        rm -f /www/html/.well-known/acme-challenge/* || :
        mkdir -p /www/html/.well-known/acme-challenge/
        certbot certonly --agree-tos --webroot -n \
            -w /www/html -d "${NGINX_HOST}" --email "${EMAIL}" \
            --pre-hook="rm -rf ${cert_path}" \
            --renew-hook 'touch $RENEWED_LINEAGE/real && nginx -s reload'
        nginx -s reload
    fi
    while true; do
        sleep 10
        echo "renewing certificate"
        certbot renew -n
        nginx -s reload --renew-hook "nginx -s reload"
        sleep $((60*60*24*15)) # 15 days
    done &
) &
wait
