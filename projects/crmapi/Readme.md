Project Name
----
**CRM API**

Description
-----------
The CRM API application provides access to CRM functions within DCM for the Wholesale clients

Infrastructure
--------
Web Tier - nginx servers behind a load balancer providing stateless proxied access to the aplication servers
Application Tier - Stateless jetty servers providing access to the java application

Dependencies
------------
Access to Cassandra DB. This currently uses the DCM database for a small number of column families.
AC and DCM application deployed and accessible

Roles
-----
webtier - common, nginx
apptier - common, java, jetty

Instance Size
-------------
webtier - m1.small
apptier - c1.medium

Variables
---------
- project_prefix: crmapi
- java_type: oracle_gz
- java_version: 7
- app_name: crm  (used for setting tomcat context)
- app_user: crmapi
- java_opts: "-Denvironment={{ env }}{{ env_prefix }} -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Xmx1024"
- f5_ip: 10.255.129.201
- f5_pool_name: uat-crmAPI-ELB
- f5_user: 
- f5_pwd: 
