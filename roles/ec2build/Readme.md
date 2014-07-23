Name
----
**ec2build**

Description
-----------
This role will create or maintain Amazon AWS instances.  The role will manage the instances, route 53 DNS records, F5 or AWS ELB load balancers and manages ansible invenotry files for each environment.

Example
--------
```python
- hosts: local
  roles:
    - ec2build
```

Dependencies
------------
none

Variables
---------
- project_prefix: provided at the command line when running the init.yml play
- env: provided at the command line when running the init.yml play
- env_num: provided at the command line when running the init.yml play
- [web,app,db]_serv: provided in the projects folder aws vars file
- [web,app,db]_ami: provided in the projects folder aws vars file
- [web,app,db]_size: provided in the projects folder aws vars file
- aws_[web,app,db]_subnet_1[ab]: provided in the projects folder aws vars file
- aws_key_name: provided in the projects folder aws vars file (default - environment name)
- [web,app,db]_group_[ab]: provided in the projects folder aws vars file
- [web,app,db]_count_[ab]: provided in the projects folder aws vars file
- aws_region: provided in the projects folder aws vars file (default - eu-west-1)


Platforms
---------
- AWS
