#!/bin/bash --login

#cd /home/osboxes/rentog
cd /var/app/current
bundle exec rake sharetribe:send_kpis:send_kpis_to_admins
