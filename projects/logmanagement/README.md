Project Name: logmanagement
Description: Deploys & manages the servers that run the log management solution
Author: Gareth Coffey

** WORK IN PROGRESS **

Environments:
This project is not environment specific and can be deployed anywhere

Variables: 
- The following run-time arguments are required:-
- project - Should be the name of the project folder e.g. project=skygoweb
- env - Should be the environment name, also used to load correct cloud env vars e.g. env=uat 
- c_type - The cloud type e.g. c_type=aws 
- tier_name - This should match the name of the tag you set in the environment var file e.g. tier_name=dbserver

Variable Hierarchy:
- There are several places in which variables can be set, all default values are loaded first and any overrides set in the environment will take precendence

Order of precedence
3. logmanagement_vars.yml - This contains standard project variables used in all environments and tiers
2. logstash_vars.yml - This contains standard tier variables used in all environments
1. aws_dev_env.yml - This contains environment specific config for all tiers

Deployment:
- Deployment is managed by the 'ec2auto' role, which will read your environment file e.g. aws_dev_env.yml
and maintain the security groups & nodes defined. 
Application roles are defined for each tier in e.g. logstash.yml with an accompanying var file e.g. logstash_vars.yml

Logstash Servers
ansible-playbook -vvv -i local projects/skygoweb/site.yml -e "project=logmanagement env=dev c_type=aws tier_name=logstash"

ElasticSearch Servers
ansible-playbook -vvv -i local projects/skygoweb/site.yml -e "project=logmanagement env=dev c_type=aws tier_name=esearch"
