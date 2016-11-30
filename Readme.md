# CRITS Docker Installation

An updated version of the CRITS docker file with crits_services installed.

Credit to the REMnux team! They provided the base docker image that allowed this to happen :)

## Running the Container - First Time Setup ( new database instance )

This sequence is a first time install of CRITS and CRITS services, in order for the Database sequence to be correctly installed ( and users created ) please follow the below.

1. Pull the mongodb container
>`docker pull mongo`

2. Create a new directory to store your mongodb data
> `mkdir -p /data/crits`

3. Assign the correct selinux context to the data directory
>`chcon -Rt svirt_sandbox_file_t /data/crits`

4. Create and save the data outside the mongodb container
> `docker run --name docker_mongo -p 27017:27017 -v /data/crits:/data/db -d mongo:latest`

5. Create a mongo client
> `docker run -it mongo mongo --host $host`
>
> Where $host is the external NIC IP address

5. Copy and paste the below code into the terminal after changing the tokens - please be aware that the below gives excessive permissions
> `use crits`
>
> `db.createUser({
  user : "$some_user_name$",
  pwd : "$password$",
  roles : [ { "role": "readWrite", "db" : "crits" } ]
  })
`

6. Ensure the above returns a success code. Exit the container by running `exit` or until you see the normal command prompt

6. Rerun the mongodb container  
> `docker stop docker_mongo && docker rm docker_mongo && docker run --name docker_mongo -p 27017:27017 -v /data/crits:/data/db -d mongo:latest --auth`

7. (Optional) Create a specific crits user and role to access MongoDB
> Refer to vendor documentation

8. Navigate to the crits directory and perform the following command
> `docker build -t aux/crits:1 .`
>
> Where the mongodb_password and mongodb_user are valid to access the mongodb database setup in earlier steps

9. First time build of the container
> `docker run --name crits --link docker_mongo:mongo -p 8443:8443 -e FIRST_BOOT=true -e MONGO_USER=$mongo_user -e MONGO_PASSWORD=$mongo_password -d aux/crits:1`
>
> This will build the relevant database and configuration

10. Grab the username and password
> `docker logs crits`
>
> This should return a username and password that can be used to access and administrate the crits instance.

# Running the container

To stop the container

`docker stop crits && docker rm crits`

To start the container

`docker run --name crits --link docker_mongo:mongo -p 8443:8443 -e MONGO_USER=$mongo_user -e MONGO_PASSWORD=$mongo_password -d aux/crits:1`

Notice the lack of the first boot parameter!

# Compatible Services

| Service | Compatible | Included in Docker File |
| :--- | :---- | :--- |
| taxii_service | yes  | yes |
| virustotal_service | yes | yes |
| zip_meta_service | yes |  yes |
| pdfinfo_service | yes | No |
| peinfo_service | yes | yes | |
| stix_validator_service | yes  | yes |
| office_meta_service | yes | yes |
| fireeye_service | yes | yes |
| diffie_service | yes  | yes |
| crits_scripts | yes  | yes |
| cf1app_service | yes | yes |
| chminfo_service | yes | yes |
| chopshop | yes |  yes |
| clamd_service | yes  | yes |
| cuckoo_service | yes  | yes |
| exiftool_service | yes | yes |
| farsight_service | yes  | yes |
| impfuzzy_service | yes  | yes |
| macro_extract_service | yes | yes |
| metacap_service | yes | yes |
| pdf2txt_service | yes | yes |
| preview_service | yes  | yes |
| pyew | yes  | yes |
| pyinstaller_service | yes  | yes |
| ratdecoder_service | yes | yes |
| shodan_service | yes | yes |
| snugglefish_service | No | No |
| ssdeep_service | yes  | yes |
| totalhash_service | yes  | yes |
| unswf_service | yes  | yes |
| whois_service |yes | yes |

## Further Upgrades

| Upgrade | Description | Status |
| :---- | :----- | :----- |
| Map SSL paramters | Allow custom ssl cert to be mapped into the crits container | Not implemented |
