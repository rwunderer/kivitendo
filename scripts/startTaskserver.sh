#!/bin/bash

/var/www/kivitendo-erp/scripts/task_server.pl debug
RV="$?"

if [ "$RV" -ne "0" ]; then
    c=5
    echo "Taskserver crashed with code ${RV}. Entering ${c}m grace period."
    echo

    while [ "$c" -gt "0" ]; do
        echo "$c min remaining"
        sleep 1m
        c=$((c - 1))
    done

    echo "Exiting."
fi

exit $RV
