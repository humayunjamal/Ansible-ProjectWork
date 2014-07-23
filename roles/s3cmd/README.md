Name
----
**s3cmd**

Description
-----------
This role installs s3cmd.

Examples
--------
```python
- hosts: dbtier
  roles:
    - s3cmd
```

Dependencies
------------
none

Variables
---------
**s3cmd_user:** Default - _root_
**s3cmd_home:** Default - _/root/_
**s3cmd_version:**
**s3cmd_archive:**

Platforms
---------
- Debian, Ubuntu
- CentOs, RedHat
