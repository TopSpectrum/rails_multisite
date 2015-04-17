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
federation:    # Tells the app to use `database.yml` as federation data, not actual data.
  cache: 4     # Number of minutes to cache this information for (false or 0 to disable caching. WARNING: SQL query every refresh! Defaults to 24 hours)
  use_default_on_miss: true # Indicates to use the master database information if the site is not found in the database. This means you need to use your load balancer (ex: nginx) to protect this site from unsupported hostnames.
```

##### How does this work?

The federation database contains a master record of where things are located. So instead of defining your sites in the yml file, you define them in the database. 

We use `config/database.yml` to figure out where your federation data is located. 

The required database schema is the same structure as the field table above.


###### Required Database Layout (federation database)

Column Name   | Column Type  | Allow Null | Default Value         | Notes                                   |
------------- | ------------ | ---------- | --------------------- | --------------------------------------- |
id            | Number       |      N     | Auto Number           | 
host          | String       |      Y     | `database.yml`        | 
username      | String       |      Y     | `database.yml`        | 
password      | String       |      Y     | `database.yml`        | 
pool          | Number       |      Y     | `database.yml` or 50  | Number of connections to keep active. 
timeout       | Number       |      Y     | `database.yml or 5000 | Amount of time to wait for a connection before giving up

```sql
CREATE TABLE `federation`.`federation_databases`
(
  `id`        BIGINT NOT NULL AUTO_INCREMENT, 
  `host`      VARCHAR(255),                    -- IP (save dns lookups) or Hostname of other database
  `username`  VARCHAR(255),                    -- Username for the other database
  `password`  VARCHAR(255),                    -- Password for the other database
  `pool`      SMALLINT,                        -- Number of connections to cache
  `timeout`   SMALLINT,                        -- Timeout in milliseconds to wait to connect
  
  PRIMARY KEY (`id`)
);

CREATE TABLE `federation`.`federation_host_names`
(
  `federation_database_id`  BIGINT NOT NULL,  -- The id of the parent (federation.federation_sites) 
  `host_name`               VARCHAR(255),     -- The hostname that rails sees (ex: smyers.net)
  
  PRIMARY KEY(`host_name`)                    -- This is the primary entry point to this dataset.
);
```

###### What's the fetch logic? (SQL Mode)

1. Someone comes to the site at `http://www.smyers.net` *(This is the first time that this site has been fetched.)*
2. We execute this SQL
```SQL
SELECT * FROM federation_databases
  INNER JOIN federation_host_names ON federation_databases.id == federation_host_names.federation_database_id
  WHERE host_name = ?
```
3. If it returns zero results, we check the `use_default_on_miss` flag. If that's `true` then we keep going. If that's `false` then we fail with "some exception".
4. If it returns 1 result, we connect over to that database *(or we use a previous connection, if cached)* and show the page *(with that database info active in `ActiveRecord`)*.





