#!/usr/bin/env bash

echo "[MailServer] Prepare Config Files ..."

if [ ! -f "/etc/mailserver/sqlgrey.conf" ]; then
    if [ ! -f "/etc/mailserver/sqlgrey.conf.example" ]; then
        cp /etc/sqlgrey/sqlgrey.conf.example /etc/mailserver/sqlgrey.conf.example
    fi
    echo "Missing configuration /etc/mailserver/sqlgrey.conf"
    exit 1
fi

if [ ! -f "/etc/mailserver/postfix.conf" ]; then
    if [ ! -f "/etc/mailserver/postfix.conf.example" ]; then
        cp /etc/postfix/postfix.conf.example /etc/mailserver/postfix.conf.example
    fi
    echo "Missing configuration /etc/mailserver/postfix.conf"
    exit 1
fi

if [ ! -f "/etc/mailserver/courier.conf" ]; then
    if [ ! -f "/etc/mailserver/courier.conf.example" ]; then
        cp /etc/courier/courier.conf.example /etc/mailserver/courier.conf.example
    fi
    echo "Missing configuration /etc/mailserver/courier.conf"
    exit 1
fi

if [ ! -f "/etc/mailserver/clients_fqdn_whitelist.local" ]; then
    cp /etc/sqlgrey/clients_fqdn_whitelist.local /etc/mailserver/clients_fqdn_whitelist.local
fi

cp /etc/mailserver/sqlgrey.conf /etc/sqlgrey/
cp /etc/mailserver/clients_fqdn_whitelist.local /etc/sqlgrey/clients_fqdn_whitelist.local

if [ -f "/etc/mailserver/spamassassin.cf" ]; then
    cp /etc/mailserver/spamassassin.cf /etc/spamassassin/override.cf
fi

cat /etc/mailserver/postfix.conf /etc/postfix/mysql_virtual_alias_maps.cf.template > /etc/postfix/mysql_virtual_alias_maps.cf
cat /etc/mailserver/postfix.conf /etc/postfix/mysql_virtual_domains_maps.cf.template > /etc/postfix/mysql_virtual_domains_maps.cf
cat /etc/mailserver/postfix.conf /etc/postfix/mysql_virtual_mailbox_maps.cf.template > /etc/postfix/mysql_virtual_mailbox_maps.cf

cat /etc/mailserver/courier.conf /etc/courier/authmysqlrc.template > /etc/courier/authmysqlrc

if [ ! -f /var/log/mail.log ]; then
    touch /var/log/mail.log
fi

cp /etc/postfix/main.cf.template /etc/postfix/main.cf
sed -i -e "s@\${HOSTNAME}@$HOSTNAME@" /etc/postfix/main.cf
sed -i -e "s@\${DOMAIN_PRIMARY}@$DOMAIN_PRIMARY@" /etc/postfix/main.cf
sed -i -e "s@\${TLS_PRIVKEY}@$TLS_PRIVKEY@" /etc/postfix/main.cf
sed -i -e "s@\${TLS_CERTFILE}@$TLS_CERTFILE@" /etc/postfix/main.cf
sed -i -e "s@\${TLS_CAFILE}@$TLS_CAFILE@" /etc/postfix/main.cf

echo "[MailServer] Combining TLS Certificates"
cat ${TLS_PRIVKEY} ${TLS_FULLCHAINFILE} > /etc/courier/imap_combined.pem

echo "[MailServer] Removing old PIDs ..."
rm -r /var/run/*.pid

echo "[MailServer] Start Services ..."

service rsyslog start
service saslauthd start
service sqlgrey start
service spamassassin start
service postfix start
service courier-authdaemon start
service courier-imap-ssl start

echo "[MailServer] Running ..."

tail -f /var/log/mail.log