#!/bin/bash

#Add the mongo user and password to the datbase file
sed -i "s/MONGO_USER = ''/MONGO_USER = '$MONGO_USER'/g" /data/crits/crits/config/database.py
sed -i "s/MONGO_PASSWORD = ''/MONGO_PASSWORD = '$MONGO_PASSWORD'/g" /data/crits/crits/config/database.py

#Condition checking for SSL certificates, this will show whether the configuration
#has been run before
if [ ! -f /data/ssl/certs/crits.crt ]
  then
    #Generate the Apache2 SSL certificate
    cd /tmp
    openssl req -nodes -newkey rsa:4096 -keyout new.cert.key -out new.cert.csr -subj "/CN=CRITs/O=auxilium/C=UK"
    openssl x509 -in new.cert.csr -out new.cert.cert -req -signkey new.cert.key -days 1825
    mv new.cert.cert /data/ssl/certs/crits.crt
    mv new.cert.key  /data/ssl/private/crits.plain.key
    a2enmod ssl
    service apache2 start
    sleep 5
    #Create the default collections needed in crits
    python /data/crits/manage.py create_default_collections
    #Create the nonroot user
    python /data/crits/manage.py users -a -A -e "nonroot@crits.local" -f "Nonroot" -l "User" -o "aux" -u "nonroot"
    #Configure the services
    python /data/crits_services_configuration.py
    printf "\n"
    echo "To access CRITS user interface, go https://localhost:8443 and use the following credentials:"
    printf "\n"
    echo "Username: nonroot"
    #Reset the password for the nonroot user
    python /data/crits/manage.py users -u nonroot -r 2
    printf "\n"
    echo "Please change the temporary password upon successful login to the web interface by clicking on 'Nonroot User' near the top left panel and selecting 'Change Password'."
    printf "\n"
    printf "\n"

  else
    #DONT RESET USER INFORMATION OR DESTROY EXISTING CONFIG IF THIS DOES NOT ALREADY EXIST
    service apache2 start
    sleep 5
    echo "To access CRITS user interface, go https://localhost:8443"
    printf "\n"
  fi
