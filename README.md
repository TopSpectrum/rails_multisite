# rails_multisite

# Editor notes to self




## Description

This README.md file is actively being developed and is a work in progress.

This plugin allows you to host multiple sites using the same runtime. In the Rails world, this is called "multisite."

### Modes of operation

This plugin has 3 modes of operation:

1. Present but inactive *(default if file missing or `multisite: false`)*
2. Active via YAML      *(default if `multisite: true`)*
3. Active via SQL       *(must be specifically set via `multisite: 'sql'`)*

#### Present but inactive

This plugin will detect the absence of a config file (`config/multisite.yml`) and then switch into inactive mode. It will not modify your application memory space.

Alternatively, you can have the `config/multisite.yml` file present, but disable it via:

```YAML
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the rails_multisite plugin.
#     The configuration is contained inside the 'multisite' key.
#     Setting this to a value of `false` will disable the plugin.
multisite: false
```

#### Active via YAML

This is the simplist *(but most limiting)* mode of operation.

The config file `config/multisite.yml` lists the hosts that you support and their database information. This information is defined at boot time and is immutable. To change the information, you must restart the app.

Set the `multisite` variable to either `true` or `yaml` *(This is because YAML mode is the default)*

```yaml
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the rails_multisite plugin.
#     The configuration is contained inside the 'federation' key.
#     Setting this key to a value of 'true' will enable the plugin in YAML mode.
multisite: true
#
# These defaults are shared among all sites. Each site entry can declare values to override these values.
# Each of these keys have defaults if not present. Most of those defaults are found in `config/database.yml` 
defaults:
  adapter: postgresql
  host: 123.123.123.123
  username: SOME_USERNAME
  password: SOME_PASSWORD
  database: smyers_net
  pool: 10                 # If not found anywhere, defaults to 25.
  timeout: 1000            # If not found anywhere, defaults to 5000.
#
# This is a site name.
# It must be unique, but this value is for your readability. The computer doesn't care. 
# Though I recommend against calling it 'blaabittyblah' or 'a' since you'll want to remember what it is for.
smyers.net:
  # 
  # All properties can be placed here to override default values.
  # Order of lookup: this -> '../defaults' -> 'config/database.yml'
  # This list is required and names must be unique across all active database configs.
  # All entries in this list will resolve to exactly the same properties (no more configuration options past this point)
  host_names:              
    - smyers.net
    - michael.smyers.net
coursescheduler.com:
  #
  # Demonstrating that the properties can be overridden.
  adapter: mysql
  password: SOME_OTHER_PASSWORD
  database: random_database_name
  host_names:
    - courseschduler.net
    - courseschduler.com
  # - smyers.net           # This would be invalid and your app would crash.
```

#### Active via federation database (sql)

Enable sql federation by setting `multisite: 'sql'` in `config/multisite.yml`

```yaml
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the rails_multisite plugin.
#     The configuration is contained inside the optional 'federation' key.
#     Setting this key to a value of 'sql' will enable the plugin in FEDERATION mode.
#     Tells the app to use `database.yml` as a federation data source, instead of using it as a real database for your domain data.
multisite: 'sql'   
#
# Since we're in federation mode, the federation settings are in the `federation` key. This key is optional.
# Default values are indicated as appropriate.
#
federation:
  # At time of writing, there is only 1 federation option.
  # 
  # If we can't find the host_name in the database, do you want to:
  #    A) ACCEPT - Fall back to the values in the `defaults` section. (set it to `defaults`)
  #    B) REJECT - Throw an error. (set it to `fail` or false)
  #    C) DEFAULT - If you don't care, just leave the key out of this file. It defaults to `defaults` (naturally).
  host_name_not_found_action: 'defaults' 
  
...
```

##### How does this work?

The federation database contains a lookup table of which database each of your sites uses. So instead of defining your host_names in the `config/multisite.yml` file, you define them in the `federation` database. *(The name is defined in `config/database.yml`)*

We use `config/database.yml` as the config file for your federation database. So you should put your *'federation database info'* into `config/database.yml` and put your *'regular database connection info'* as rows in your federation database.

###### Federation Database Layout (federation database)

```sql
-- The database name of `federation` is configured in your `config/database.yml` file. You could change it if you wanted.

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

###### Walk me through the fetch logic for `Federation Mode`.

1. Someone comes to the site at `http://www.smyers.net/something/fancy` *(This is the first time that this site has been fetched.)*
2. We execute this SQL *(with `host_name = www.smyers.net`)*
```SQL
SELECT federation_databases.*,federation_host_names.database FROM federation_databases
  INNER JOIN federation_host_names ON federation_databases.id = federation_host_names.federation_database_id
  WHERE host_name = ?
```
3. If it returns `zero` results, we check the `config/multisite.yml|federation.host_name_not_found_action` flag. If that's `defaults` then we *'keep going'* and set the `default federation database` for use with `ActiveRecord` for this request. If that's `false` or `fail` then we fail with `"some exception"`.
4. If it returns `one` result, we connect over to that database *(or we use a previous connection, if cached)* and *'keep going'* with `that database info` active in `ActiveRecord`.
5. We allow for fallback, so `database` = defaultString(try_first: `federation_host_names.database`, try_last: `federation_databases.database`)
6. It's not possible to return more than one result, because the host_name is unique.

### Advanced config options

#### 1. Environment aware config

```YAML
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the rails_multisite plugin.
#     This example shows how to scope each site by environment
#     
multisite: false           # Globally default to disabled.
development: 
  multisite: false         # Redeclare disabled for development. Unnecessary, but shows scoping.
test:
  multisite: true          # YAML mode for test
  
production:
  multisite: 'federation'  # In-file yml mode for production. When true, searches for keys for config data.
  smyers.net:              #
    ...
```



