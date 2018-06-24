FROM debian:jessie
MAINTAINER Christian Simon <mail@christiansimon.eu>

ENV DOMAIN_PRIMARY=christiansimon.eu
ENV TLS_PRIVKEY=/etc/ssl/mailserver/privkey.pem
ENV TLS_CERTFILE=/etc/ssl/mailserver/cert.pem
ENV TLS_CAFILE=/etc/ssl/mailserver/chain.pem
ENV TLS_FULLCHAINFILE=/etc/ssl/mailserver/fullchain.pem
ENV MAILMAN_ALIASMAPS=hash:/var/lib/mailman/data/aliases
ENV DEBIAN_FRONTEND noninteractive

# Postfix/Courier non-interactive setup
RUN echo "postfix postfix/mailname string ${DOMAIN_PRIMARY}" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
RUN echo "courier-base courier-base/webadmin-configmode boolean true" | debconf-set-selections

RUN groupadd -r --gid 5000 vmail \
  && useradd -r --uid 5000 -g vmail -d /var/vmail -s /bin/false -m vmail

RUN apt-get update \
  && mkdir -p /var/run/courier/authdaemon \
  && touch /var/run/courier/authdaemon/pid.lock \
  && apt-get install -y apt-utils \
  && apt-get install --no-install-recommends -y \
    postfix postfix-mysql spamassassin spamc maildrop sqlgrey gamin \
    courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl \
    libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql rsyslog mysql-client less

# Mailman non-interactive setup
RUN echo "de_DE.UTF-8 UTF-8" > /etc/locale.gen \
    && apt-get install -y mailman \
    && apt-get clean \
    && echo "mailman  mailman/default_server_language select de" | debconf-set-selections \
    && echo "mailman  mailman/site_languages multiselect de" | debconf-set-selections \
    && echo "mailman  mailman/used_languages string de" | debconf-set-selections \
    && dpkg-reconfigure mailman

COPY maildroprc /etc/maildroprc

COPY spamassassin/local.cf /etc/spamassassin/

COPY sqlgrey/clients_fqdn_whitelist.local /etc/sqlgrey/
COPY sqlgrey/sqlgrey.conf.example /etc/sqlgrey/

COPY postfix/sasl/smtpd.conf /etc/postfix/sasl/smtpd.conf
COPY postfix/*.cf /etc/postfix/
COPY postfix/*.template /etc/postfix/
COPY postfix/postfix.conf.example /etc/postfix/

COPY courier/authdaemonrc /etc/courier/
COPY courier/authmysqlrc.template /etc/courier/
COPY courier/imapd-ssl /etc/courier/
COPY courier/pop3d-ssl /etc/courier/

COPY defaults/* /etc/default/

COPY init-service.sh /usr/local/bin/
RUN chmod a+x /usr/local/bin/init-service.sh

VOLUME /home/postfix
VOLUME /etc/mailserver
VOLUME ["/etc/mailman/", "/var/lib/mailman/data"]

# SMTP
EXPOSE 25

# IMAP (SSL)
EXPOSE 993

# WEB
EXPOSE 80

CMD ["/usr/local/bin/init-service.sh"]
