Name
----
**java**

Description
-----------
This role installs java.

Example
--------
```python
- hosts: apptier
  roles:
    - java
```

Dependencies
------------
none

Variables
---------
- java_type - oracle or openjdk or oracle_gz
- java_version
- java_url
- java_base_dir
- java_path
- java_gz_file (if java_type is oracle_gz)

Platforms
---------
- Debian, Ubuntu
