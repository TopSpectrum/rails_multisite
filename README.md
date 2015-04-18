# RailsMultisite

**Gem Version:** 0.1.0  
**Author:** [Michael Smyers](https://meta.discourse.org/users/msmyers)  
**Contributor:** [Sam Saffron](https://meta.discourse.org/users/sam)  
**Date:** 4/17/2015  

## How to install

Add this line to your application's Gemfile:

```Ruby
gem 'rails_multisite'
```

And then execute:

```Ruby
$ bundle
```

Or install it yourself as:

```Ruby
$ gem install rails_multisite
```

## Description

This plugin allows your rails app to host multiple sites using the same runtime. In the Rails world, this is called "multisite."

It was written for [Discourse](http://www.discourse.org) users to be able to host multiple forums with a single rails codebase. For this reason, as a design principal, the code must be 100% compatible with the existing Discourse `config/multisite.yml` solution. This Gem extends that functionality with database lookups and caching.

The intention of this plugin is to allow Discoure to handle *a theoretical million* sites with only 1 running server. This Gem should *at the very least* cause no overhead. The performance of Discourse shall be the same, as measured by requests per second, whether you are hosting 1 site or *a theoretical million* sites.

### Modes of operation

This plugin has 3 modes of operation:

1. Inactive 
2. Active with YAML only
3. Active with SQL and YAML

#### Mode: Inactive

When you install this Gem, **it is disabled by default.** When inactive, this Gem will not modify your application memory space. You can safely install it without munging your whole app up. *(Note, if this happens, we are very sorry, and not to blame.)*

You must enable it by creating the file `config/multisite.yml` and setting `multisite: true` for it to be enabled.

Alternatively, you can have the `config/multisite.yml` file present, but disable it via `multisite: false`.

```YAML
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the Gem.
#     The configuration is contained inside the 'multisite' key.
#     Setting this to a value of `false` will disable the Gem.
#     Setting this to a value of `true` will enable the Gem.
multisite: false
```

#### Active via YAML-only

This is the simplist *(but most limiting)* mode of operation.

The config file `config/multisite.yml` lists the hosts that your runtime supports and their database information. This information is defined at boot time and is immutable. To change the information in the YAML file, you must edit the file and restart the app. For large scale apps, this behavior is not desirable.

**To start the magic** set the `multisite` variable to `true` *(magic not guaranteed)*

```yaml
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the rails_multisite plugin.
#     The configuration is contained inside the 'multisite' key.
#     Setting this key to a value of 'true' will enable the Gem.
multisite: true
#
# These defaults are shared among all sites. Each site entry can declare values to override these values.
# Each of these properties have defaults if not present. 
# These defaults are for each site that your runtime supports.
site_defaults:
  #
  # The sql adapter to use. Has some fancy defaults.
  # default 1: Whatever you have set in `config/database.yml`
  # default 2: 'postgresql'
  adapter: postgresql      
  # 
  # Where to find your database.
  # default 1: Whatever you have set in `config/database.yml`
  # default 2: localhost
  host: 123.123.123.123 
  #
  # The username for the database
  # default 1: Whatever you have set in `config/database.yml`
  # default 2: 'webapp' 
  username: SOME_USERNAME
  #
  # The password for the database
  # default 1: Whatever you have set in `config/database.yml`
  # default 2: 'password'
  password: SOME_PASSWORD
  #
  # The database name inside your running postgresql instance.
  # default 1: Whatever you have set in `config/database.yml`
  # default 2: ---- CRASH ---- 
  database: smyers_net
  #
  # How many connections to put in the connection cache.
  # default 1: Whatever you have set in `config/database.yml`
  # default 2: 10
  pool: 10
  #
  # How long to wait for a database connection before crashing.
  # default 1: Whatever you have set in `config/database.yml`
  # default 2: 5000
  timeout: 1000
#
# This is a site name. It's just for you. The Gem doesn't use this name for anything.
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
  # - smyers.net           # This would be invalid and your app would crash since it would be a dupe.
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
  # - smyers.net           # This would be invalid and your app would crash since it would be a dupe.
```

#### Active via YAML and SQL.

To understand how the YAML/SQL fallback works, I will share a story.

Larry went to the browser and typed in a DNS entry that hit your app. Here's the logic breakdown:

1. Larry accesses site via **http://www.smyers.net/is/awesome?verified=true** *(for example)*
2. This Gem intercepts the call.
3. This Gem iterates through each `resolution_strategy`.
4. The first one is 'local' (in-memory YAML) and looks up *www.smyers.net* in the in-memory hash.
5. It's not found. Bummer.
6. We check the second `resolution_strategy` 
7. Turns out the next step is `database` *(aka: the federation database)* 
8. Check the *federation database* and look up *www.smyers.net*
9. If we had found data, we could have carried on. But we didn't. Bummer.
10. What's the next `resolution_strategy`? There isn't one. We're out of things to try.
11. Check the `cache_strategy` settings.
12. Turns out we want to cache the misses. Inserts into the `miss_cache` *(evicting another miss token if we're full)* 
13. **SCENARIO 1:** Checks the `host_name_not_found_action` property and discovers it's set to `site_defaults` - loads the default database info and shows the site.
14. **SCENARIO 2:** Checks the `host_name_not_found_action` property and discovers it's set to `fail` - throws a nasty error and calls the cops on the intruder *(cop module not provided)*

**How do you take advantage of it?** You have to replace the `multisite: true` with an expanded config set.

```yaml
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the rails_multisite plugin.
#     This content demonstrates how to setup SQL-fallback for federation lookup.
#
# The multisite property is not `false` or null, so it's enabled.
multisite: 
  # 
  # The `resolution_strategies` property defines the strategy for resolving sites. 
  # 
  # By default we only do 'local'. This means you need to specifically mention database to get database lookups. 
  # 
  # Also, the name `database` is not a magic string. Want two database fallbacks instead of 1? Just put in the value
  # `database1`, `database2` and then add `resolution_strategy_database1` keys to the config.
  #
  # Want the defaults? Just say `resolution_strategies: true` and you get [local]
  #    (or simply remove it, because that's the default)
  # Want database lookup? Set `resolution_strategies: [local, database]`
  # Want the database to take precendence over the YAML? Swap it to [database, local] 
  #
  # default: [local]
  resolution_strategies: [local, database]
  #
  # If we can't find the site in any lookup, you have options. Do you want to:
  #    SITE_DEFAULTS  : Accept the traffic. Use the values in the `site_defaults` section. (set it to `site_defaults` or `true` or null (remove the key entirely))
  #    FAIL           : (default value) Throw an error. (set it to `fail` or false)
  host_name_not_found_action: 'fail' 
  #
  # Want to disable all caching? Set `cache_strategy: false`
  # Caching really only makes sense if you use a slow lookup strategy. The local YAML lookups never result in a 
  # cache insertion. They are magical like that. All other non-'local' resolution_strategies use the same cache settings.
  cache_strategy:
    #
    # It's possible to cache misses so that if someone keeps hitting you with the same bad url OVER AND OVER again, 
    # then it won't bring down your site via lookup intensity. 
    # default: true
    cache_the_misses: true
    #
    # For obvious reasons, you'll want to cache the hits. No reason to look that up every request!
    # default: true
    cache_the_hits: true
    # 
    # What's the first problem we all encounter when we cache things? Out of memory.
    # default: 1000
    overall_cache_limit: 1000
    #  
    # Ideally you want every site that you host to be cache in memory. So make this appropriately large and buy 
    # memory for your box. If not possible, then active sites will be cached, and inactive ones will drop off the
    # cache.
    # default: 1000
    hit_cache_limit: 1000
    #
    # The miss cache is pretty efficient, so we'll make that large. If someone is hitting you with a zillion fake 
    # names, use appropriate solutions for that. This is not a security Gem, it's just a helpful precaution.
    # default: 10k
    miss_cache_limit: 10000
  #
  #  This is how you define the database that contains your federation data.
  # This is technically an optional property. If absent, we default to `site_defaults`
  resolution_strategy_database: 
    #
    # Currently we only support type 'database', so this is the natural default. This property exists because the 
    # word 'database' is not a magic string. It's just a lookup in this YAML file.
    # 
    # default: database
    type: database
    #
    #
    # Because it's type:database, all of the properties found in `site_defaults` also work here.
    #
    ... 
  
site_defaults:
  ... 
  
smyers.net:
  ...
  
coursescheduler.com:
  ... 

  
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
3. If it returns **zero** results, we check the `host_name_not_found_action` flag. If that's `site_defaults` then we *'keep going'* and set the `default federation database` for use with `ActiveRecord` for this request. If that's `false` or `fail` then we fail with `"some exception"`.
4. If it returns **one** result, we connect over to that database *(or we use a previous connection, if cached)* and *'keep going'* with `that database info` active in `ActiveRecord`.
5. We allow for fallback, so `database = defaultString(try_first: federation_host_names.database, try_last: federation_databases.database)`
6. It's not possible to return **more than one** result, because the host_name is unique.

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
  multisite:  
    ...                    # Super complex production settings that uses 40 database fallbacks!
  smyers.net:              
    ...                    # In-memory YAML data too.
```



