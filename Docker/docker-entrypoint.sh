#!/bin/sh

set -eo pipefail

TX_SMTP_RELAY_HOST=${TX_SMTP_RELAY_HOST?Missing env var TX_SMTP_RELAY_HOST}
TX_SMTP_RELAY_MYHOSTNAME=${TX_SMTP_RELAY_MYHOSTNAME?Missing env var TX_SMTP_RELAY_MYHOSTNAME}
TX_SMTP_RELAY_USERNAME=${TX_SMTP_RELAY_USERNAME?Missing env var TX_SMTP_RELAY_USERNAME}
TX_SMTP_RELAY_PASSWORD=${TX_SMTP_RELAY_PASSWORD?Missing env var TX_SMTP_RELAY_PASSWORD}
TX_SMTP_RELAY_NETWORKS=${TX_SMTP_RELAY_NETWORKS:-10.0.0.0/8,127.0.0.0/8,172.17.0.0/16,192.0.0.0/8}
TX_SMTP_MESSAGE_SIZE=${TX_SMTP_MESSAGE_SIZE:-10240000}

echo "Setting configuration"
echo "TX_SMTP_RELAY_HOST        -  ${TX_SMTP_RELAY_HOST}"
echo "TX_SMTP_RELAY_MYHOSTNAME  -  ${TX_SMTP_RELAY_MYHOSTNAME}"
echo "TX_SMTP_RELAY_USERNAME    -  ${TX_SMTP_RELAY_USERNAME}"
echo "TX_SMTP_RELAY_PASSWORD    -  (hidden)"
echo "TX_SMTP_RELAY_NETWORKS    -  ${TX_SMTP_RELAY_NETWORKS}"

# Create postfix folders
mkdir -p /var/spool/postfix/
mkdir -p /var/spool/postfix/pid

# Write SMTP credentials
echo "${TX_SMTP_RELAY_HOST} ${TX_SMTP_RELAY_USERNAME}:${TX_SMTP_RELAY_PASSWORD}" > /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
rm /etc/postfix/sasl_passwd

# Log to stdout
postconf -e "maillog_file=/dev/stdout"

# http://www.postfix.org/COMPATIBILITY_README.html#smtputf8_enable
postconf -e "smtputf8_enable = no"

# Disable local mail delivery
postconf -e "mydestination="

# Limit message size to 10MB
postconf -e "message_size_limit=$TX_SMTP_MESSAGE_SIZE"

# Reject invalid HELOs
postconf -e "smtpd_delay_reject=yes"
postconf -e "smtpd_helo_required=yes"
postconf -e "smtpd_helo_restrictions=permit_mynetworks,reject_invalid_helo_hostname,permit"

# This makes sure the message id is set. If this is set to no dkim=fail will happen.
postconf -e "always_add_missing_headers = yes"

# Set allowed networks
postconf -e "mynetworks = ${TX_SMTP_RELAY_NETWORKS}"

# Configure postfix hostname
postconf -e "myhostname = ${TX_SMTP_RELAY_MYHOSTNAME}"

# Setup relay configuration
postconf -e "relayhost = ${TX_SMTP_RELAY_HOST}"
postconf -e "smtp_sasl_auth_enable = yes"
postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
postconf -e "smtp_sasl_security_options=noanonymous"
postconf -e "smtp_use_tls = yes"

# Use 587 (submission)
sed -i -r -e 's/^#submission/submission/' /etc/postfix/master.cf

# Update aliases database. It's not used, but postfix complains if the .db file is missing
postalias /etc/postfix/aliases

echo
echo 'postfix configured. Ready for start up.'
echo

exec "$@"


