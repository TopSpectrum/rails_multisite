# ruby_multisite

## Description

This README.md file is actively being developed and is a work in progress.

This plugin allows you to host multiple sites using the same runtime. In the Ruby world, this is called "multisite."

### Modes of operation

This plugin has 3 modes of operation:

1. Present but inactive
2. Active via YAML
3. Active via federation database 

#### Present but inactive

This plugin will detect the absence of a config file (multisite.yml) and then switch into inactive mode. It will not modify your application memory space.

#### Active via YAML

This is the simplist (but most limiting) mode of operation.

The config file (multisite.yml) lists the hosts that you support and their database information. This information is defined at boot time and is immutable. To change the information, you must restart the app.

```yaml
smyers.net:
  adapter: postgresql
  database: smyers_net
  pool: 25
  timeout: 5000
  db_id: 1 # must be unique across all sites
  host_names:
    - smyers.net
    - michael.smyers.net
coursescheduler.com:
  adapter: postgresql
  host: 123.123.123.123
  username: SOME_USERNAME
  password: SOME_PASSWORD
  database: random_database_name
  pool: 25
  timeout: 5000
  db_id: 2 # must be unique across all sites
  host_names:
    - courseschduler.net
    - courseschduler.com
```

#### Active via federation database

The config file (multisite.yml) is still present, but it contains the site name of `default` 


```yaml
default:
  adapter: postgresql
  host: 123.123.123.123
  username: SOME_USERNAME
  password: SOME_PASSWORD
  database: smyers_net
  pool: 25
  timeout: 5000
  db_id: 1 # must be unique across all sites
```


