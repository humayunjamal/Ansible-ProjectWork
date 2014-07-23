Name
----
**cassandra**

Description
-----------
This role installs cassandra.

Example
--------
```python
- hosts: dbtier
    - cassandra
```

Dependencies
------------
- java

Variables
---------
- cluster_name [mandatory]
- cassandra_seeds [mandatory]

Platforms
---------
- Debian, Ubuntu
- CentOS, RedHat
