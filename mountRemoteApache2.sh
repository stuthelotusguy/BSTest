#!/bin/bash

# External server used for the demo. WARNING! use with extreme caution while the demo may be in progress.
#sudo sshfs -o allow_other root@internal-labmediaserver.crabdance.com:/var/www/html /var/www/html

# internal server used by You.i to help with development
sudo sshfs -o allow_other root@internal-labmediaserver.crabdance.com:/var/www/html /var/www/html
