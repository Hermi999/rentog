#!/bin/bash --login

#cd /home/osboxes/rentog
cd /var/app/current
bundle exec rake sharetribe:device_return_notifications:deliver