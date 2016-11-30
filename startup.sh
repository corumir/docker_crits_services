
sed -i "s/MONGO_USER = ''/MONGO_USER = '$MONGO_USER'/g" /data/crits/crits/config/database.py
sed -i "s/MONGO_PASSWORD = ''/MONGO_PASSWORD = '$MONGO_PASSWORD'/g" /data/crits/crits/config/database.py


if [ "$FIRST_BOOT" == "true" ]
  then
    python /data/crits/manage.py create_default_collections
    python /data/crits/manage.py users -a -A -e "nonroot@crits.local" -f "Nonroot" -l "User" -o "REMnux" -u "nonroot"
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf & > /data/log/startup.log
    sleep 5
    python /data/crits_services_configuration.py
    printf "\n"
    echo "To access CRITS user interface, go https://localhost:8443 and use the following credentials:"
    printf "\n"
    echo "Username: nonroot"
    echo -n "Password: "
    python /data/crits/manage.py users -u nonroot -r 2> /dev/null | grep ^New | awk -F:\  '{print $2}'
    printf "\n"
    echo "Please change the temporary password upon successful login to the web interface by clicking on 'Nonroot User' near the top left panel and selecting 'Change Password'."
    printf "\n"
    printf "\n"

  else
    #DONT RESET USER INFORMATION OR DESTROY EXISTING CONFIG IF THIS DOES NOT ALREADY EXIST
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf & > /data/log/startup.log
    sleep 5
    echo "To access CRITS user interface, go https://localhost:8443"
    printf "\n"
  fi
