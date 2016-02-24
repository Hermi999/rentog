#!/bin/bash --login

#cd /home/osboxes/rentog
cd /var/app/current
bundle exec rake sharetribe:deliver_device_return_notifications:deliver
