#!/usr/bin/env python
"""
This script is designed to perform consistent configuration for the CRITS Services
API by filling in the appropriate fields.

This should only be executed once to ensure that the database isn't unnessecarily
overwritten
"""

import pymongo
import os
import subprocess
import time

MONGO_USER = os.environ.get('MONGO_USER')
MONGO_PASSWORD = os.environ.get('MONGO_PASSWORD')

client = pymongo.MongoClient('mongodb://%s:%s@mongo/crits' % (MONGO_USER,MONGO_PASSWORD))

crits_config_collection = client['crits']['config']
crits_services_collection = client['crits']['services']

crits_config_collection.update({},{'$addToSet':{'service_dirs':'/data/crits_services'}})

#Restart the apache2 service
time.sleep(10)
subprocess.call("/usr/bin/supervisord --user=root -c /etc/supervisor/conf.d/supervisord.conf & > /data/log/startup.log", shell=True)
time.sleep(10)

#exiftool_service
crits_services_collection.update({'name':'exiftool'},{'$set':{'config':{'exiftool_path':'/usr/bin/exiftool'},'status':'available'}})

#upx_service
crits_services_collection.update({'name':'upx'},{'$set':{'config':{'upx_path':'/usr/bin/upx'},'status':'available'}})

#Chopshop
crits_services_collection.update({'name':'ChopShop'},{'$set':{'config':{'basedir':'/usr/local/bin/chopshop'},'status':'available'}})

#pyew
crits_services_collection.update({'name':'Pyew'},{'$set':{'config':{'pyew':'/usr/bin/pyew'},'status':'available'}})

#Yara
crits_services_collection.update({'name':'yara'},{'$set':{'config':{'sigdir':'/data/rules'},'config':{'sigfiles':['index.yar']},'status':'available'}})

#Setup the taxii stanza for hailataxii - first need to include a source, then the config itself
client['crits']['source_access'].insert_one({
    "schema_version" : 1,
    "name" : "TAXII",
    "active" : "on",
    "sample_count" : 0})

crits_services_collection.update({'name':'taxii_service'},{'$set':{
    'config.taxii_servers' : {
        'hailataxii' : {
            'hostname' : 'hailataxii',
            'ppath' : '/taxii-data',
            'ipath' : '/taxii-data',
            'version' : 0,
            'user' : 'guest',
            'https' : False,
            'lcert' : "",
            'keyfile' : "",
            'port' : "",
            'pword' : 'guest',
            'feeds' : []
            }
        }

    }
    }
)

#crits_services_collection.update({'name':'taxii_service'},{'$push':{
#    'config.taxii_servers.hailataxii.feeds':{ "0" : {
#       'fcert' : None,
#       'def_impact' : None,
#       'feedname' : 'guest.dataForLast_7daysOnly',
#       'subID' : None,
#       'source' : 'TAXII',
#       'def_conf' : 'unknown',
#       'fkey' : None,
#       'last_poll' : None
#    } }
#}
#}
#)

#Then modify the mongodb configuration for the services
for document in crits_services_collection.find({'status':'available'}):
    crits_services_collection.update({'_id':document['_id']},{'$set':{'enabled':True}})
