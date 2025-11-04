FROM debian:13.1@sha256:58035749da00efb7c658f01ae1ef0afbcc4399433da24096a57a005b661ded59

# parameter 
#ARG BUILD_TZ="Europe/Berlin"
ENV locale=de_DE
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

#Packages
RUN apt-get -qq update && apt-get -y upgrade && apt-get install -y apache2 libarchive-zip-perl libclone-perl \
        libconfig-std-perl libdatetime-perl libdbd-pg-perl libdbi-perl \
    libemail-address-perl  libemail-mime-perl libfcgi-perl libjson-perl \
    liblist-moreutils-perl libnet-smtp-ssl-perl libnet-sslglue-perl \
    libparams-validate-perl libpdf-api2-perl librose-db-object-perl \
    librose-db-perl librose-object-perl libsort-naturally-perl \
    libstring-shellquote-perl libtemplate-perl libtext-csv-xs-perl \
    libtext-iconv-perl liburi-perl libxml-writer-perl libyaml-perl \
    libimage-info-perl libgd-gd2-perl libapache2-mod-fcgid \
    libfile-copy-recursive-perl libalgorithm-checkdigits-perl \
    libcrypt-pbkdf2-perl git libcgi-pm-perl libtext-unidecode-perl libwww-perl\
    aqbanking-tools poppler-utils libhtml-restrict-perl\
    libdatetime-set-perl libset-infinite-perl liblist-utilsby-perl\
    libdaemon-generic-perl libfile-flock-perl libfile-slurp-perl\
    libfile-mimeinfo-perl libpbkdf2-tiny-perl libregexp-ipv6-perl \
    libcam-pdf-perl libmath-round-perl libtry-tiny-perl \
    libterm-readline-gnu-perl libimager-qrcode-perl libimager-perl librest-client-perl libipc-run-perl \
    libmail-imapclient-perl libencode-imaputf7-perl libuuid-tiny-perl \
    linuxdoc-tools-latex preview-latex-style texlive-latex-base texlive-lang-german \
    texlive-lang-greek texlive-base-bin texlive-latex-recommended texlive-fonts-recommended \
    texlive-latex-extra texlive-lang-german ghostscript latexmk \
    gettext-base tzdata \
    libdatetime-event-cron-perl libexception-class-perl && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set timezone
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

#ADD KIVITENDO
ARG BUILD_KIVITENDO_VERSION="3.8.0"
RUN rm -rf /var/www/kivitendo-erp && git clone https://github.com/kivitendo/kivitendo-erp.git /var/www/kivitendo-erp && \
    cd /var/www/kivitendo-erp && git checkout release-${BUILD_KIVITENDO_VERSION%-*}
COPY conf/kivitendo.conf /var/www/kivitendo-erp/config/kivitendo.conf.in

#Configure the taskserver
#scripts/boot/upstart/kivitendo-task-server.conf nach /etc/init/kivitendo-task-server.conf
#ADD /conf/kivitendo-task-server.service /etc/init/kivitendo-erp/config/kivitendo.conf
#RUN service kivitendo-task-server start

#Check Kivitendo installation
RUN cd /var/www/kivitendo-erp/ && \
    envsubst < /var/www/kivitendo-erp/config/kivitendo.conf.in > /var/www/kivitendo-erp/config/kivitendo.conf && \
    perl /var/www/kivitendo-erp/scripts/installation_check.pl -v && \
    rm /var/www/kivitendo-erp/config/kivitendo.conf

# Setup APACHE as ``root`` user
USER root
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd

# Update the default apache site with the config 
COPY conf/apache-config.conf /etc/apache2/apache2.conf
COPY conf/apache-default.conf /etc/apache2/sites-available/000-default.conf

# SET Servername to localhost
RUN echo "ServerName localhost" >> /etc/apache2/conf-available/servername.conf && a2enconf servername

# Manually set up the apache environment variables
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/tmp
ENV APACHE_LOCK_DIR=/tmp
ENV APACHE_PID_FILE=/tmp/apache2.pid
ENV APACHE_RUN_DIR=/tmp
ENV APACHE_SERVERADMIN=admin@localhost
ENV APACHE_SERVERNAME=localhost
ENV APACHE_SERVERALIAS=docker.localhost
ENV APACHE_DOCUMENTROOT=/var/www
 
# Prepare Kivitendo writable mounts, ensure executable bit on progs
RUN mv /var/www/kivitendo-erp/users /var/www/kivitendo-erp/.users && \
    mv /var/www/kivitendo-erp/config /var/www/kivitendo-erp/.config && \
    mkdir -p /var/www/kivitendo-erp/users && \
    mkdir -p /var/www/kivitendo-erp/spool && \
    mkdir -p /var/www/kivitendo-erp/webdav && \
    mkdir -p /var/www/kivitendo-erp/config && \
    find /var/www/kivitendo-erp -name "*.pl" -exec chmod a+x {} \;

# Perl Modul im Apache laden
RUN a2enmod cgi.load && \
    a2enmod fcgid.load

RUN a2disconf other-vhosts-access-log

# set Port
EXPOSE 8080

# Add VOLUMEs for writable mounts
VOLUME ["/tmp", "/var/www/kivitendo-erp/users", "/var/www/kivitendo-erp/spool", "/var/www/kivitendo-erp/webdav", "/var/www/kivitendo-erp/config", "/var/www/kivitendo-erp/templates"]

# update kivi config and start apache
COPY /scripts/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh
USER www-data
ENTRYPOINT ["/usr/local/bin/startKivi.sh"]
