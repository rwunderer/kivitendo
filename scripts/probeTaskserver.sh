#!/bin/bash

set -euo pipefail

kill -0 "$(cat /var/www/kivitendo-erp/users/pid/config.kivitendo.conf.pid)"
