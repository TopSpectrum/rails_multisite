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

**multisite.yml:**
```yaml
smyers.net:
  db_id: 1 # must be unique across all sites
  adapter: postgresql
  host: 123.123.123.123
  username: SOME_USERNAME
  password: SOME_PASSWORD
  database: smyers_net
  pool: 25
  timeout: 5000
  host_names:
    - smyers.net
    - michael.smyers.net
coursescheduler.com:
  db_id: 2 # must be unique across all sites
  adapter: postgresql
  host: 123.123.123.123
  username: SOME_USERNAME
  password: SOME_PASSWORD
  database: random_database_name
  pool: 25
  timeout: 5000
  host_names:
    - courseschduler.net
    - courseschduler.com
```

#### Active via federation database

The config file (multisite.yml) is still present, but it contains the site name of `default`. At time of writing, all other entries will be ignored if the `default` entry is present.

**multisite.yml:**
```yaml
federation:true # Tells the app to use `database.yml` as federation data, not actual data.
```

##### How does this work?

The federation database contains a master record of where things are located. So instead of defining your sites in the yml file, you define them in the database. 

We use `config/database.yml` to figure out where your federation data is located. 

The required database schema is the same structure as the field table above.


###### Required Database Layout (federation database)

Column Name   | Column Type  | Allow Null | Default Value        | Notes                                   |
------------- | ------------ | ---------- | -------------------- | --------------------------------------- |
id            | Number       |      N     | Auto Number          | 
host          | String       |      Y     | `database.yml`       | 
username      | String       |      Y     | `database.yml`       | 
password      | String       |      Y     | `database.yml`       | 
pool          | Number       |      Y     | `database.yml` || 50 | Number of connections to keep active. I
timeout       | Number       |      Y     | 5000                 | Amount of time to wait for a connection before giving up

```sql
CREATE TABLE `federation`.`federation_sites`
(
  `id`        INTEGER NOT NULL AUTO_INCREMENT, 
  `host`      VARCHAR(255),                    -- IP (save dns lookups) or Hostname of other database
  `username`  VARCHAR(255),                    -- Username for the other database
  `password`  VARCHAR(255),                    -- Password for the other database
  `pool`      SMALLINT,                        -- Number of connections to cache
  `timeout`   SMALLINT,                        -- Timeout in milliseconds to wait to connect
  
  PRIMARY KEY (`id`)
)
```

