#!/bin/bash --login
# * * * * * /bin/bash --login /var/app/current/cronjobs_every_minute.sh >> ~/cron_log.txt 2>&1

cd /var/app/current
bundle exec rake ts:index
