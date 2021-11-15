#!/bin/bash

cp -a /var/www/kivitendo-erp/.config/* /var/www/kivitendo-erp/config/
envsubst < /var/www/kivitendo-erp/.config/kivitendo.conf.in > /var/www/kivitendo-erp/config/kivitendo.conf

cp -a /var/www/kivitendo-erp/.users/* /var/www/kivitendo-erp/users/
cp -a /var/www/kivitendo-erp/.users/.??* /var/www/kivitendo-erp/users/

#sed -i "/TEXT_TO_BE_REPLACED/c $REPLACEMENT_TEXT_STRING" /tmp/foo
#sed -i '/TEXT_TO_BE_REPLACED/c\This line is removed by the admin.' /tmp/foo
# service kivitendo-task-server start

#systemctl daemon-reload
# systemctl enable kivitendo-task-server.service
# systemctl start kivitendo-task-server.service

# host     = postgres_container
# port     = 5432
# db       = kivitendo_auth
# user     = postgres
# password = changeme

[ -d "${APACHE_RUN_DIR}" ] || mkdir -p ${APACHE_RUN_DIR}

exec apache2 -DFOREGROUND
