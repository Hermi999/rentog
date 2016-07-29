#!/bin/bash --login
# 0,30 * * * * /bin/bash --login /var/app/current/cronjobs_every_30min.sh >> ~/cron_log.txt 2>&1

#cd /home/osboxes/rentog
cd /var/app/current
bundle exec rake sharetribe:device_event_notifications:deliver
