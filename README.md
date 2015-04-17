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

The federation database contains a master record of where things are located. So instead of defining your sites in the `config/multisite.yml` file, you define them in the `federation.federation_databases` database. 

We use `config/database.yml` as the database for your federation data. So you should put your `federation` database info into `config/database.yml` and put your *'regular database connection info'* as rows in your federation database.

###### Required Database Layout (federation database)

```sql
-- The database name of `federation` is configured in your `config/database.yml` file

CREATE TABLE `federation`.`federation_databases`
(
  `id`        BIGINT NOT NULL AUTO_INCREMENT, 
  
  `host`      VARCHAR(255),       -- IP (save dns lookups) or Hostname of other database
  `username`  VARCHAR(255),       -- Username for the other database
  `password`  VARCHAR(255),       -- Password for the other database
  `pool`      SMALLINT,           -- Number of connections to cache
  `timeout`   SMALLINT,           -- Timeout in milliseconds to wait to connect
  
  `database`  VARCHAR(255),       -- The database name to use on this host. (can be null)
                                  -- If both parent/child are null, defaults to your `database.yml` value.
  PRIMARY KEY (`id`)
);

CREATE TABLE `federation`.`federation_host_names`
(
  `federation_database_id`  BIGINT NOT NULL,  -- The id of the parent (federation.federation_sites) 
  `host_name`               VARCHAR(255),     -- The hostname that rails sees (ex: smyers.net)
  `database`                VARCHAR(255),     -- The database name to use for this host name. 
                                              -- If null, defaults to parent value.
                                              -- If both parent/child are null, defaults to your `database.yml` value.
  
  PRIMARY KEY(`host_name`)                    -- This is the primary entry point to this dataset.
);
```

###### What's the fetch logic? (SQL Mode)

1. Someone comes to the site at `http://www.smyers.net` *(This is the first time that this site has been fetched.)*
2. We execute this SQL *(with `host_name = www.smyers.net`)*
```SQL
SELECT federation_databases.*,federation_host_names.database FROM federation_databases
  INNER JOIN federation_host_names ON federation_databases.id = federation_host_names.federation_database_id
  WHERE host_name = ?
```
3. If it returns `zero` results, we check the `use_default_on_miss` flag. If that's `true` then we *'keep going'* with the `default federation database` active in `ActiveRecord`. If that's `false` then we fail with `"some exception"`.
4. If it returns `one` result, we connect over to that database *(or we use a previous connection, if cached)* and *'keep going'* with `that database info` active in `ActiveRecord`.





