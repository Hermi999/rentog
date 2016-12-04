#!/bin/bash --login
# 0 1 * * * /bin/bash --login /var/app/current/cronjobs_daily_at_night.sh >> ~/cron_log.txt 2>&1

#cd /home/osboxes/rentog
cd /var/app/current
bundle exec rake sharetribe:device_return_notifications:deliver
bundle exec rake sharetribe:sort_custom_fields:sort_customer_values
bundle exec rake sharetribe:sort_listings:sort_listings
