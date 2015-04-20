# RailsMultisite

**Gem Version:** 1.0.0  
**Author:** [Michael Smyers](https://meta.discourse.org/users/msmyers)  
**Contributor:** [Sam Saffron](https://meta.discourse.org/users/sam)  
**Date:** 4/17/2015  

## Development Schedule

### Milestone 1 *(4/20/15)*

* Clone existing functionality into this Gem.
* Publish Gem into public/global Gem repositories.
* No effective change will be made to the Gem. This will be version *1.0.0*

### Milestone 2 *(4/22/15)*

* Ability to query federation data via SQL

### Milestone 3 *(4/30/15)*

* Encapsulate each query into a reusable *strategy* function and allow settings to stipulate the lookup order.

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

The intention of this plugin is to allow Discoure to handle *a theoretical million* sites with only 1 running server. This Gem should *at the very least* cause no overhead. The performance of Discourse shall be the same, as measured by requests per second, whether you are hosting 1 site or *a theoretical million* sites. **This will be verified with performance load testing.**

**NOTE:** This README.md document will be revised to match the current version. 

### Modes of operation

This plugin has 2 modes of operation:

1. Inactive 
2. Active with YAML

#### Mode: Inactive

When you install this Gem, **it is disabled by default.** When inactive, this Gem will not modify your application memory space. You can safely install it without munging your whole app up. *(Note, if this happens, we are very sorry, and not to blame.)*

You must activate it by creating the file `config/multisite.yml` and inserting the sites that you would like to have.

##### Inactive

```YAML
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the Gem.
#     This file is currently empty, so it is therefore disabled.
```

#### Active 

The config file `config/multisite.yml` lists the hosts that your runtime supports and their database information. This information is defined at boot time and is immutable. To change the information in the YAML file, you must edit the file and restart the app. For large scale apps, this behavior is not desirable.

**To start the magic** add your sites *(magic not guaranteed)*

```yaml
# @file: config/multisite.yml
# @description: 
#     This file defines the configuration for the rails_multisite plugin.
#     The configuration is contained inside the 'multisite' property.
#     Having sites defined in this file will enable this Gem.

# This is a site name. It's just for you. The Gem doesn't use this name for anything.
# It must be unique, but this value is for your readability. The computer doesn't care. 
# Though I recommend against calling it 'blaabittyblah' or 'a' since you'll want to remember what it is for.
smyers.net:
  adapter: postgresql      
  host: 123.123.123.123 
  username: SOME_USERNAME
  password: SOME_PASSWORD
  database: smyers_net
  pool: 10
  timeout: 1000
  host_names:
   - smyers.net
   - michael.smyers.net
   - smyers.com
coursescheduler.com:
  adapter: postgresql      
  host: 123.123.123.123 
  username: SOME_USERNAME
  password: SOME_PASSWORD
  database: some_random_database_name
  host_names:
    - coursescheduler.net
    - coursescheduler.com
```

