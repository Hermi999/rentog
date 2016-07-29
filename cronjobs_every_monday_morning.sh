#!/bin/bash --login
# 0 1 * * 1 /bin/bash --login /var/app/current/cronjobs_every_monday_morning.sh >> ~/cron_log.txt 2>&1

#cd /home/osboxes/rentog
cd /var/app/current
bundle exec rake sharetribe:send_kpis:send_kpis_to_admins
