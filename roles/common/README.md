Name
----
**common**

Description
-----------
This role applies base setup tasks. For instance, 
- creates the base directory structure where applications will be deployed
- installs and configures collectd
- installs and configures ntp
- installs and configures rsyslog
- sets up secure ephemeral storage (if required)
- sets up mountpoint for non EBS disks (if required)

Example
--------
```python
- hosts: apptier
  roles:
    - common
```

Dependencies
------------
none

Variables
---------
**base_dir:** Defaults - _/var/sky_
**base_log_dir:** Used to update rsyslog config
**base_pid_dir:** Used for custom init scripts where PID tracking is required
**graphite_host:** Default - _graphite_
**graphite_port:** Default - _2003_
**keys_path:** Used for dynamic dns updater script
**use_sec_eph:** Whether secure ephemeral storage should be provisioned
**processes:** [] list of processes for collectd to monitor
**add_proxy:** Default - _false_
**http_proxy:** Default - _http://proxy:80/_

Platforms
---------
- Debian, Ubuntu
