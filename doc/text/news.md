# News

## 7.2.2: 2025-06-08 {#release-7-2-2}

### Improvements

  * Removed deprecated `:primary_key` and `:foreign_key` on
    `has_many`.
    * GH-205
    * GH-206
    * Patch by J-Verz

  * Removed deprecated `ActiveLdap::ConnectionNotEstabilished`.
    * GH-205
    * GH-207
    * Patch by J-Verz

  * Removed deprecated `estabilish_connection`.
    * GH-205
    * GH-208
    * Patch by J-Verz

  * Removed deprecated `:ldap_scope` configuration option.
    * GH-205
    * GH-209
    * Patch by J-Verz

  * Removed deprecated callback by instance methods on instances.
    * GH-205
    * GH-210
    * Patch by J-Verz

  * Removed deprecated `:foreign_key` on `belongs_to :many`.
    * GH-205
    * GH-211
    * Patch by J-Verz

  * Added support for multiple server configurations.
    * GH-204
    * GH-212
    * Patch by J-Verz

### Thanks

  * J-Verz

## 7.2.1: 2024-10-02 {#release-7-2-1}

### Fixes

  * Fixed a bug that ActiveLdap doesn't work with Rails 7.0.
    * GH-200
    * Patch by Carlos Palhares

### Thanks

  * Carlos Palhares

## 7.2.0: 2024-09-24 {#release-7-2-0}

### Improvements

  * Added support for Active Model 7.2.

  * Dropped support for Active Model 5.

  * Dropped support for Active Model 6.

  * Added support for Psych 4.
    * GH-198
    * Patch by Carlos Palhares.

### Fixes

  * net-ldap: Fixed paged search
    * GH-197
    * Patch by Patrick Marchi

### Thanks

  * Patrick Marchi

  * Carlos Palhares

## 7.0.0: 2024-02-23 {#release-7-0-0}

### Improvements

  * Added support for Active Model 7.
    * GH-193
    * GH-194
    * GH-195
    * Patch by J-Verz.

### Thanks

  * J-Verz

## 6.1.0: 2020-12-24 {#release-6-1-0}

### Improvements

  * Changed to use `:use_paged_results` option value by default.
    [GitHub#189][Reported by Kevin McCormack]

### Thanks

  * Kevin McCormack

## 6.0.4: 2020-12-06 {#release-6-0-4}

### Improvements

  * Enabled concurrency by default.
    [GitHub#188][Reported by Kevin McCormack]

### Thanks

  * Kevin McCormack

## 6.0.3: 2020-08-17 {#release-6-0-3}

### Improvements

  * Added support for `save(validate: false)`.
    [GitHub#180][Reported by Kevin McCormack]

  * jndi: Added support for follow referrals.
    [GitHub#182][Patch by Kevin McCormack]

### Fixes

  * Fixed a bug that sub base is ignored in DN specified by `new`.
    [GitHub#185][Reported by Kevin McCormack]

### Thanks

  * Kevin McCormack

## 6.0.2: 2020-05-19 {#release-6-0-2}

### Improvements

  * Added `options` to {ActiveLdap::Persistance#reload}.
    [GitHub#176][Reported by Kevin McCormack]

  * jndi: Improved DN escaping.
    [GitHub#178][Patch by Kevin McCormack]

### Thanks

  * Kevin McCormack

## 6.0.1: 2020-04-21 {#release-6-0-1}

### Improvements

  * Dropped support for Ruby 2.4.

  * Stopped using paged results when we need only one entry.
    [GitHub#173][Patch by Kevin McCormack]

### Thanks

  * Kevin McCormack

## 6.0.0: 2020-04-16 {#release-6-0-0}

### Improvements

  * Removed needless `rubyforge_project` from `.gemspec`.
    [GitHub#167][Patch by Olle Jonsson]

  * Added support for reusing parent configuration for omitted
    configuration items when creating a connection per class or DN.

  * jndi: Added support for processing DN that includes backslash.

  * jndi: Added a CI job for JRuby 9.
    [GitHub#170][Patch by Kevin McCormack]

  * jndi: Added support for paged search.
    [GitHub#171][Patch by Kevin McCormack]

  * Added support for Active Model 6.

  * `search`: Added `:used_paged_results` and `:page_size` options.

### Thanks

  * Olle Jonsson

  * Kevin McCormack

## 5.2.3: 2019-02-15 {#release-5-2-3}

### Improvements

* Changed to use add and delete for modify if it's needed.
  [GitHub#156][Patch by David Klotz]

* Added support for timezone with munites offset such as `0530`.
  [GitHub#160][GitHub#161][Patch by Neng Xu]

* Added support for Ruby 2.6.

### Thanks

* David Klotz

* Neng Xu

## 5.2.2: 2018-07-12 {#release-5-2-2}

### Improvements

* Added `:tls_options` option.
  [GitHub#156][Patch by David Klotz]

### Thanks

* David Klotz

## 5.2.1: 2018-06-13 {#release-5-2-1}

### Fixes

* Fixed a bug that configuration may be removed unexpectedly.
  [GitHub#155][Reported by Juha Erkkilä]

### Thanks

* Juha Erkkilä

## 5.2.0: 2018-05-09 {#release-5-2-0}

### Improvements

* Added `:dc_base_class` and `:ou_base_class` options to
  `ActiveLdap::Populate.ensure_base`.
  [GitHub#153][Patch by hide_24]

* Added Active Model 5.2.0 support.

* Improved connection error handling for net-ldap.

### Thanks

* hide_24

## 5.1.1: 2018-01-17 {#release-5-1-1}

### Improvements

* Added `:include_operational_attributes` convenient option to
  `ActiveLdap::Base.find`. `ActiveLdap::Base.find(...,
  :include_operational_attributes => true)` equals to
  `ActiveLdap::Base.find(..., :attributes => ["*", "+"])`.
  [GitHub#150][Reported by jas01]

### Thanks

* jas01

## 5.1.0: 2017-05-01 {#release-5-1-0}

### Improvements

* Supported Rails 5.1.0.

* Supported sub class instantiate by objectClass.
   [GitHub#134][Patch by Chris Garrigues]

* Improved error messages.

* Changed to the default LDAP client to net-ldap from ruby-ldap
  because ruby-ldap doesn't support timeout.

* Suppressed warnings.
  [GitHub#146][Reported by jas01]

### Fixes

* Added missing dependency.
  [GitHub#145][Reported by Tom Wardrop]

### Thanks

* Chris Garrigues

* Tom Wardrop

* jas01

## 4.0.6: 2016-04-07 {#release-4-0-6}

### Improvements

* Updated supported Ruby versions.
  [GitHub#127] [Patch by weicheng]
* Supported spaces in DN.
  [GitHub#129] [Patch by belltailjp]

### Thanks

* weicheng
* belltailjp

## 4.0.5: 2016-01-20 {#release-4-0-5}

### Improvements

* Supported `unicodePwd` in Active Directory
  [GitHub#105] [Reported by Laas Toom]
* Supported Blowfish, SHA-256 and SHA-512 password hash with salt.
  [GitHub#108] [Patch by Gary Richards]
* Supported Ruby 2.2.
  [GitHub#115] [Reported by Jan Zikan]
  [GitHub#125] [Patch by Bohuslav Blín]
* Supported Ruby 2.3.

### Fixes

* Fixed documentation for `rails generate`.
  [GitHub#107] [Patch by Gary Richards]

### Thanks

* Laas Toom
* Gary Richards
* Jan Zikan
* Bohuslav Blín

## 4.0.4: 2014-10-11 {#release-4-0-4}

### Improvements

* Migrated to commit mail mailing list to "Google
  Groups":https://groups.google.com/forum/?hl=ja#!forum/activeldap-commit
  from RubyForge. Thanks to RubyForge! RubyForge was very helpful!
* Update project homepage URL in README.
  [GitHub#103] [Patch by Adam Whittingham]
* Removed needless `Enumerable` inclusion in `ActiveLdap::Base`.
  [GitHub#104] [Patch by Murray Steele]
* {ActiveLdap::Populate.ensure_base}: Supported ou entry creation in base DN.
* Added `follow_referrals` configuration. You can disable auto
  referrals following by specifying `false`. It is useful when you
  can't access referrals.

  This configuration is enabled by default.

  This configuration works only with ruby-ldap adapter.

  [GitHub#99] [Suggested by hadmut]

* Supported `bindname` extension in LDAP URL such as
  `ldap://host/dc=base,dc=name????bindname=cn%3Dadmin%2Cdc%3Dexample%2Cdc%3Dcom%3F`.

### Fixes

* Fixed a bug logging is failed on removing a connection.
  [GitHub#94] [Reported by Francisco Miguel Biete]
* Fixed homepage URL in RubyGems.
  [GitHub#95] [Patch by Vít Ondruch]
* Fixed a bug that DN in LDAP URL is used as bind DN not base DN.

### Thanks

* Francisco Miguel Biete
* Vít Ondruch
* Adam Whittingham
* Murray Steele
* hadmut

## 4.0.3: 2014-05-15 {#4-0-3}

### Improvements

* Supported stopping colorize logging by `config.colorize_logging = false`.
  [GitHub:#81] [Reported by nengxu]
* Supported PagedResults defined in RFC 2696 in the net-ldap adapter.
  [activeldap-discuss] Paged results
  [Suggested by Aaron Knister]
* Supported PagedResults defined in RFC 2696 in the ldap adapter.
  [GitHub#83] [Patch by Aaron Knister]
* Stopped to override ORM generator by default.
  [GitHub#87] [Patch by Josef Šimánek]
* Supported Rails 4.1.0.
  [GitHub#90] [Patch by Francisco Miguel Biete]
* document: Removed obsoleted description.
  [activeldap-discuss] [Reported by Jarod Watkins]
* Supported `ActiveLdap::Base.attribute_method?` .
  [GitHub#92] [Reported by Renaud Chaput]

### Fixes

* Fixed a bug that `belongs_to :many` 's inconsistent behavior.
  You get DN attribute when you add an entry by DN attribute to
  belongs_to :many collection. It should return entry object instead of
  DN attribute. Because loaded collection returns entry objects.
  [activeldap-discuss] [Reported by Jarod Watkins]

### Thanks

* nengxu
* Aaron Knister
* Josef Šimánek
* Francisco Miguel Biete
* Jarod Watkins
* Renaud Chaput

## 4.0.2: 2014-01-04 {#4-0-2}

### Improvements

* Supported sub-tree moving by all adapters.
* Used YARD style link in documentation. [Reported by Fraser McCrossan]
* Supported Object-Security-Descriptor (OID: 1.2.840.113556.1.4.907)
  [GitHub:#66] [Reported by Nowhere Man]
* Made JEPG syntax binary.
* Supported binary encoding for values in a container.
  [GitHub:#66] [Reported by Nowhere Man]
* Added documentation about `:filter` option of {ActiveLdap::Base.find}
  into tutorial.
  [GitHub:#72] [Patch by Fernando Martinez]
* Migrated to gettext gem from gettext_i18n_rails gem because ActiveLdap
  dosen't use any gettext_i18n_rails gem features..
  [activeldap-discuss] [Reported by Christian Nennemann]
* Supported retry on timeout on JNDI adapter.
  [GitHub:#77] [Patch by Ryosuke Yamazaki]

### Fixes

* Removed needless newlines generated by `pack("m")`.
  [GitHub:#75] [GitHub:#76] [Patch by Ryosuke Yamazaki]
* Fixed a bug that `after_initialize` isn't run.
  [GitHub:#79] [Patch by Nobutaka OSHIRO]

### Thanks

* Fraser McCrossan
* Nowhere Man
* Fernando Martinez
* Christian Nennemann
* Ryosuke Yamazaki
* Nobutaka OSHIRO

## 4.0.1: 2013-08-29 {#4-0-1}

### Improvements

* Added ActiveLdap::EntryAttribute#exist?.
* [GitHub:#66] Improved Active Directory support.
  Binary data can be validated correctly. [Reported by Nowhere Man]
* [GitHub:#6][GitHub:#69] Improved setup description in tutorial.
  [Reported by Radosław Antoniuk] [Patch by Francisco Miguel Biete]
* [GitHub:#56] Supported moving sub-tree. It requires Ruby/LDAP 0.9.13 or later,
  JRuby or net-ldap 0.5.0 or later. (net-ldap 0.5.0 isn't released yet.)
  [Reported by Jean-François Rioux]

### Fixes

* [GitHub:#65] Removed removed attributes values by removing
  objectClasses. [Reported by mbab]

### Thanks

* mbab
* Nowhere Man
* Radosław Antoniuk
* Francisco Miguel Biete
* Jean-François Rioux

## 4.0.0: 2013-07-13 {#4-0-0}

### Improvements

* [activeldap-discuss] Added {ActiveLdap::Entry} for convenient.
  [Suggested by Craig White]
* [GitHub:#45] Ensured that {ActiveLdap::Persistence#save!} returns
  true on success. But you should use {ActiveLdap::Persistence#save}
  to determine success or failure by return value.
  [Reported by Suggested by Erik M Jacobs]
* [GitHub:#52] Improved binary data handling on Ruby 1.9.3.
  [Patch by Carl P. Corliss]
* [GitHub:#53] Supported lower case hashed password.
  [Patch by jpiotro3]
* [GitHub:#51] Supported implicit railtie load by
  `require "active_ldap"`.
  [Patch by mperrando]
* [GitHub:#62] Improved JNDI communication error handling.
  [Patch by Ryosuke Yamazaki]
* [GitHub:#61] Supported Rails 4. Dropped Rails 3 support.
  [Patch by superscott]
* [GitHub:#63] Handled Errno::ECONNRESET as connection in
  net-ldap adapter [Patch by mpoornima]

### Fixes

* [GitHub:#44] Fixed a typo in document.
  [Patch by Vaucher Philippe]
* [GitHub:#50] Fixed a stack overflow during SASL bind to a
  unresponsive LDAP server.
  [Patch by pwillred]
* [GitHub:#54] Fixed a link in document.
  [Patch by marco]
* [GitHub:#57] Fixed a wrong blank value detection for "false".
  [Reported by Robin Doer]

### Thanks

* Craig White
* Vaucher Philippe
* Erik M Jacobs
* pwillred
* Carl P. Corliss
* jpiotro3
* marco
* mperrando
* Robin Doer
* Ryosuke Yamazaki
* superscott
* mpoornima

## 3.2.2: 2012-09-01 {#3-2-2}

* Supported entry creation by direct ActiveLdap::Base use.
  [Reported by Craig White]
* Started to use Travis CI.

### Thanks

* Craig White

## 3.2.1: 2012-08-31 {#3-2-1}

* Fixed a bug that ActiveLdap::Base#delete doesn't work.
  [Reported by Craig White]

### Thanks

* Craig White

## 3.2.0: 2012-08-29 {#3-2-0}

* [GitHub:#39] Supported Rails 3.2.8. [Reported by Ben Langfeld]
* [GitHub:#13] Don't use deprecated Gem.available?. [Patch by sailesh]
* [GitHub:#19] Supported new entry by `ha_many :wrap`. [Patch by Alex Tomlins]
* Supported `:only` option in XML output.
* [GitHub:#14] Supported nil as single value. [Reported by n3llyb0y]
* [GitHub:#20] Supported ActiveModel::MassAssignmentSecurity.
  [Reported by mihu]
* [GitHub:#24] Supported Ruby 1.9 style Hash syntax in generator.
  [Patch by ursm]
* [GitHub:#25][GitHub:#39] Supported ActiveModel::Dirty.
  [Patch by mihu][Reported by Ben Langfeld]
* [GitHub:#26] Improved speed for dirty. [Patch by mihu]
* [GitHub:#28] Improved speed for initialization. [Patch by mihu]
* [GitHub:#29] Added .gemspec. [Suggested by mklappstuhl]
* [GitHub:#34] Removed an unused method. [Patch by mihu]
* [GitHub:#37] Improved will_paginate support. [Patch by Craig White]
* [GitHub:#40] Added missing test files to .gemspec. [Reported by Vít Ondruch]
* [GitHub:#41] Improved speed for find. [Patch by unixmechanic]
* Changed i18n backend to gettext from fast_gettext again.
* [GitHub:#42] Fixed a bug that optional second is required for GeneralizedTime.
  [Reported by masche842]

### Thanks

* sailesh
* Alex Tomlins
* n3llyb0y
* mihu
* ursm
* Ben Langfeld
* mklappstuhl
* Craig White
* Vít Ondruch
* unixmechanic
* masche842

## 3.1.1: 2011-11-03 {#3-1-1}

* Supported Rails 3.1.1.
* [GitHub:#9] Fixed a typo in document. [warden]
* [GitHub:#11] Added persisted?. [bklier]
* [GitHub:#16] Supported 4 or more bytes salt for SSHA and SMD5.
  [Alex Tomlins]

### Thanks

* warden
* bklier
* Alex Tomlins

## 3.1.0: 2011-07-09 {#3-1-0}

* Supported Rails 3.1.0.rc4.
  [Ryan Tandy, Narihiro Nakamura, Hidetoshi Yoshimoto]
* Removed ActiveRecord dependency and added ActiveModel dependency.
* Used YARD instead of RDoc as documentation sysytem.

## 1.2.4: 2011-05-13

* Splited AL-Admin into other repository: https://github.com/activeldap/al-admin
* [GitHub:#2] Fixed "path po cound not be found" error by fast_gettext.
  [rbq]

## 1.2.3: 2011-04-30

* [#40] Ignored nil value attribute.
  [christian.pennafort]
* [#48] Escaped ":" in filter value.
  [planetmcd]
* Added missing rubygems require.
  [spoidar]
* Used fast_gettext instead of gettext.
  [Peter Fern]
* Supported Rails 2.3.11.
  [Kris Wehner]
* Fixed wrong assertion in test.
  [Ryan Tandy]

### Thanks

* christian.pennafort
* planetmcd
* spoidar
* Peter Fern
* Kris Wehner
* Ryan Tandy

## 1.2.2: 2010-07-04

* Supported ActiveRecord 2.3.8 and Rails 2.3.8.
* [#37] Fixed gem dependencies in Rakefile. [zachwily]
* Fixed a bug that setting 'false' but 'nil' is returned. [Hideyuki Yasuda]
* Supported non-String attribute value as LDIF value. [Matt Mencel]
* Worked with a LDAP server that uses 'objectclass' not 'objectClass' as
  objectClass attribute name. [Tim Hermans]
* [#41] Provide SASL-option support, primarily for authzid
  [Anthony M. Martinez]
* [#43] Error with to_xml [ilusi0n.x]
* [#44] Accept '0' and '1' as boolean value [projekttabla]
* [#27429] Fixed inverted validatation by validate_excluded_classes
  [Marc Dequènes]
* Supported DN attribute value for assosiation replacement.
  [Jörg Herzinger]

## 1.2.1: 2009-12-15

* Supported ActiveRecord 2.3.5 and Rails 2.3.5.
* Supported GetText 2.1.0 and Locale 2.0.5.
* belongs_to(:many) support DN attribute.
* [#31] ActiveLdap::Base#attributes returns data that reflects
  schema definition. [Alexey.Chebotar]
* blocks DN attribute change by mass assignment with :id => ....
* [#35] fix has_many association is broken. [culturespy]
* Supported nested attribute options. [Hideyuki Yasuda]

## 1.2.0: 2009-09-22

* Supported ActiveRecord 2.3.4 and Rails 2.3.4.
* [IMCOMPATIBLE]
  [#23932] Inconsistant DN handling in object attributes [Marc Dequènes]
  (ActiveLdap::Base#dn and ActiveLdap::Base#base return
  ActiveLdap::DN not String)
* [#26824] support operational attributes detection [Marc Dequènes]
  (added ActiveLdap::Schema::Attribute#directory_operation?)
* [#27] Error saving an ActiveLDAP user [brad@lucky-dip.net]
* [#29] Raised on modify_rdn_entry when rdn already exists [Alexey.Chebotar]
* Added ActiveLdap::DN.parent.
* Supported renaming an entry. Renaming other DTI is only supported by
  JNDI backend.

## 1.1.0: 2009-07-18

* Improved tutorial. [Kazuaki Takase]
* Improvements:
  * API:
    * [#26] Supported to_xml for associations. [achemze]
    * ActiveLdap::Base.delete_all(filter=nil, options={}) ->
    ActiveLdap::Base.delete_all(filter_or_options={}).
    Sure, old method signature is also still supported.
    * belongs_to(:many) with :foreign_key is deprecated.
    Use :primary_key instead of :foreign_key. [Kazuaki Takase]
    * Means of has_many's :primary_key and :foreign_key are inverted.
    [Kazuaki Takase]
    * [experimental] Added ldap_field ActionView helper to
    generate form fileds for a LDAP entry.
  * Suppressed needless attributes updating.
* Dependencies:
  * Re-supported GetText.
  * ActiveRecord 2.3.2 is only supported.

## 1.0.9

* Added documents in Japanese. [Kazuaki Takase]
* Supported Ruby 1.9.1.
  * [#20] [Ruby 1.9 Support] :: Running Tests [Alexey.Chebotar]
* Supported Rails 2.3.2.
  * [#18] [Rails 2.3 Support] :: Running WEBrick Hangs [Alexey.Chebotar]
* Bug fixes:
  * Fixed blank values detection. [David Morton]
  * [#22] Ruby 1.8.6 p287 :: Undefined methods [Alexey.Chebotar]
  * Fixed gem loading. [Tiago Fernandes]
  * Fixed DN change via #base=. [David Morton]
  * Fixed infinite retry on timeout.
  * Fixed needless reconnection.
* API improvements:
  * Removed needless instance methods: #prefix=,
   #dn_attribute=, #sort_by=, #order=, #required_classes=,
   #recommended_classes= and #excluded_classes. [David Morton]
  * Removed obsolete scafoold_al generator.
  * Reduced default :retry_limit.
  * Supported association as parameter. [Joe Francis]
  * Normalized schema attribute name. [Tim Hermans]
  * Suppressed AuthenticationError -> ConnectionError
   conversion on reconnection. [Kazuaki Takase]
  * Added ActiveLdap::Schema#dump.
  * ActiveLdap::Base.establish_connection ->
   ActiveLdap::Base.setup_connection.
  * Supported ActiveLdap::Base.find(:last).
  * Added convenient methods:
    * ActiveLdap::Base.first
    * ActiveLdap::Base.last
    * ActiveLdap::Base.all

## 1.0.2

* Removed Base64 module use.
* Improved LDIF parser.
* Improved scheme parser.
* Supported Base64 in XML serialization.
* Supported TLS options.
* Supported ActiveRecord 2.2.2.
* Supported Ruby on Rails 2.2.2.
* Used rails/init.rb and rails_generators/ directory structure convention
  for Rails and gem. rails/ directory will be removed after 1.0.2 is released.
* AL-Admin migrated to Ruby on Rails 2.2.2 form 2.0.2.
* Improved ActiveDirectory integration.
* Accepted :class_name for belong_to and has_many option.
* Improved default port guess.
* Bug fixes:
  * [#4] ModifyRecord#load doesn't operate atomic. [gwarf12]
  * [#5] to_xml supports :except option. [baptiste.grenier]
  * [#6] to_xml uses ActiveResource format. [baptiste.grenier]
  * Out of ranged GeneralizedTime uses Time.at(0) as fallback value.
   [Richard Nicholas]
  * ActiveLdap::Base#to_s uses #to_ldif. [Kazuhiro NISHIYAMA]
  * Fixed excess prefix extraction. [Grzegorz Marszałek]
  * Skiped read only attribute validation. [しまさわらさん]
  * Treated "" as empty value. [Ted Lepich]
  * [#9][#16] Reduced raising when DN value is invalid.
   [danger1986][Alexey.Chebotar]
  * [#10][#12] Fixed needless ',' is appeared. [michael.j.konopka]
  * [#11] Required missing 'active_ldap/user_password'. [michael.j.konopka]
  * [#13] Returned entries if has_many :wrap has nonexistent entry.
   [ingersoll]
  * [#15] Fixed type error on computing DN. [ery.lee]
  * ">=" filter operator doesn't work. [id:dicdak]
  * [#17] ActiveLdap::Base.create doesn't raise exception. [Alexey.Chebotar]

## 1.0.1

* Fixed GetText integration.
* Fixed ActiveLdap::Base.find with ActiveLdap::DN. (Reported by Jeremy Pruitt)
* Fixed associated bugs. (Reported by CultureSpy)
* Supported ActiveLdap::Base#attribute_present? with nonexistence attribute.
  (Reported by Matt Mencel)
* Added ActiveLdap::Base#.to_ldif_record.
* Improved inspect.
* Supported ActiveSupport 2.1.0.

## 1.0.0

* Fixed GSSAPI auth failure. [#18764] (Reported by Lennon Day-Reynolds)
* Supported Symbol as :dn_attribute_value. [#18921] (Requested by Nobody)
* Improved DN attribute detection. (Reported by Iain Pople)
* Avoided unnecesally modify operation. (Reported by Tilo)

## 0.10.0

* Implemented LDIF parser.
* Improved validation:
  * Added some validations.
  * Fixed SINGLE-VALUE validation. [#17763]
   (Reported by Naoto Morishima)
* Supported JNDI as backend.
* Improved auto reconnection.
* Supported Rails 2.0.2.
* Improved performance. (4x)
* [API CHANGE]: removed "'binary' =>" from getter result.

  <pre>
  !!!plain
  e.g.:
    before:
        user.user_certificate # => {"binary" => "..."}
       now:
        user.user_certificate # => "..."
  </pre>

* Added :excluded_classed ldap_mapping option.
* Logged operation time used for LDAP operation.
* Improved API:
  * Accepted non String value for find(:value => XXX).
   (Suggested by Marc Dequèn)
  * Accepted DN as ActiveLdap::Base.new(XXX).
   (Reported by Jeremy Pruitt)
  * Treated empty password for smiple bind as anonymous bind.
   (Suggested by Bodaniel Jeans)
  * Ensured adding "objectClass" for find's :attribute value. [#16946]
   (Suggested by Nobody)
  * Fixed a GeneralizedTime type casting bug.
   (Reported by Bodaniel Jeanes)
  * Supported :base and :prefix search/find option value escaping.
   (Suggested by David Morton)

## 0.9.0

* Improved DN handling.
* Supported attribute value validation by LDAP schema.
* Changed RubyGems name: ruby-activeldap -> activeldap.
* Removed Log4r dependency.
* Supported lazy connection establishing.
  * [API CHANGE]: establish_connection doesn't connect LDAP server.
* [API CHANGE]: Removed ActiveLdap::Base#establish_connection.
* Added ActiveLdap::Base#bind. (use this instead of #establish_connection)
* Supported implicit acts_as_tree.
* [API CHANGE]: Supported type casting.
* Supported :uri option in configuration.
* Improved Rails integration:
  * Followed Rails 2.0 changes.
  * AL-Admin:
    * Supported lang parameter in URL.
    * Improved design a bit. (Please someone help us!)
    * Supported schema inspection.
    * Supported objectClass modifiation.
  * Rails plugin:
    * Added ActiveLdap::VERSION check.
    * Added model_active_ldap generator.
    * Renamed scaffold_al generator to scaffold_active_ldap.

## 0.8.3

* Added AL-Admin Sample Rails app
* Added Ruby-GetText-Package support
* Added a Rails plugin
* Improved schema handling
* Improved performance
* Many bug fixes

## 0.8.2

* Added Net::LDAP support!
  * supported SASL Digest-MD5 authentication with Net::LDAP.
* improved LDAP server support:
  * improved Sun DS support.
  * improved ActiveDirectory support. Thanks to Ernie Miller!
  * improved Fedora-DS support. Thanks to Daniel Pfile!
* improved existing functions:
  * improved DN handling. Thanks to James Hughes!
  * improved SASL bind.
  * improved old API check.
  * improved schema handling. Thanks to Christoph Lipp!
  * improved filter notification.
* updated documents:
  * updated Rails realted documenation. Thanks to James Hughes!
  * updated documentation for the changes between 0.7.1 and 0.8.0.
   Thanks to Buzz Chopra!
* added new features:
  * added scaffold_al generator for Rails.
  * added required_classes to default filter value. Thanks to Jeff Hall!
  * added :recommended_classes option to ldap_mapping.
  * added :sort_by and :order options to find.
  * added ActiveLdap::Base#to_param for ActionController.
* fixed some bugs:
  * fixed rake install/uninstall.
  * fixed typos. Thanks to Nobody!
  * fixed required_classes initialization. Thanks to James Hughes!

## 0.8.1

* used Dependencies.load_paths.
* check whether attribute name is available or not.
* added test for find(:first, :attribute => 'xxx', :value => 'yyy').
* supported ActiveSupport 1.4.0.
* make the dual licensing of ruby-activeldap clear in the README.
* followed edge Rails: don't use Reloadable::Subclasses if doesn't need.
* added examples/.
* removed debug code.
* normalized attribute name to support wrong attribute names in MUST/MAY.
* supported getting dn value by Base#[].
* test/test_userls.rb: followed userls changes.
* update the doc href.
* provide a dumb example of how to use the old association(return_objects) style API with the new awesome API.
* followed new API.
* removed a finished task: support Reloadable::Subclasses.

## 0.8.0

* Makefile/gemspec system replaced with Rakefile + Hoe
* Bugfix: Allow base to be empty
* Add support for Date, DateTime, and Time objects (patch from Patrick Cole)
* Add support for a :filter argument to override the default attr=val LDAP search filter in find_all() and find() (patch from Patrick Cole)
* Add Base#update_attributes(hash) method which does bulk updates to attributes (patch from Patrick Cole) and saves immediately
* API CHANGE: #attributes now returns a Hash of attribute_name => clone(attribute_val)
* API CHANGE: #attribute_names now returns an alphabetically sorted list of attribute names
* API CHANGE;
* Added attributes=() as the implementation for update_attributes(hash) (without autosave)
* API TRANSITION: Base#write is now deprecated. Please use Base#save
* API TRANSITION: Added SaveError exception (which is a subclass of WriteError for now)
* API TRANSITION: Base.connect() is now deprecated. Please use Base.establish_connection()
* API TRANSITION: Base.close() is now deprecated. Please use Base.remove_connection()
* API TRANSITION: :bind_format and :user of Base.establish_connection() are now deprecated. Please use :bind_dn
* Added update_attribute(name, value) to update one attribute and save immediately
* #delete -> #destroy
* Base.destroy_all
* Base.delete(id) & Base.delete_all(filter)
* add Base.exists?(dnattr_val)
* attr_protected
* Base.update(dnattr_val, attributes_hash) - instantiate, update, save, return
* Base.update_all(updates_hash, filter)
* attribute_present?(attribute) - if not empty/nil
* has_attribute?(attr_name)  - if in hash
* reload() (refetch from LDAP)
* make save() return false on fail
* make save!() raise EntryNotSaved exception
* to_xml()
* `clear_active_connections!()` -- Conn per class
  * make @@active_connections and name them by
* base_class() (just return the ancestor)
* Separate ObjectClass changes to live in ActiveLDAP::ObjectClass
  * add_objectclass
  * remove_objectclass
  * replace_objectclass
  * disallow direct objectclass access?
* support ActiveRecord::Validations.
* support ActiveRecord::Callbacks.
* rename to ActiveLdap from ActiveLDAP to integrate RoR easily and enforce
  many API changes.

## 0.7.4

* Bugfix: do not base LDAP::PrettyError on RuntimeError due to rescue evaluation.
* Bugfix: :return_objects was overriding :objects in find and find_all
* Rollup exception code into smaller space reusing similar code.

## 0.7.3

* Made has_many and belongs_to use :return_objects value
* Force generation of LDAP constants on import - currently broken

## 0.7.2

* Stopped overriding Conn.schema in ldap/schema - now use schema2
* Fix attributes being deleted when changing between objectclasses with shared attributes
* Added schema attribute case insensitivity
* Added case insensitivity to the attribute methods.
* Added LDAP scope override support to ldap_mapping via :scope argument. (ldap_mapping :scope => LDAP::LDAP_SCOPE_SUBTREE, ...)
* Fixed the bug where Klass.find() return nil (default arg for find/find_all now '*')
* Added :return_objects to Base.connect()/configuration.rb -- When true, sets the default behavior in Base.find/find_all to return objects instead of just the dnattr string.
* Hid away several exposed private class methods (do_bind, etc)
* Undefined dnattr for a class now raises a ConfigurationError
* Centralized all connection management code where possible
* Added Base.can_reconnect? which returns true if never connected or below the :retries limit
* Added block support to Base.connection to ensure "safe" connection usage. This is not just for internal library use. If you need to do something fancy with the connection object, use Base.connection do |conn| ...
* Fixed object instantiation in Base#initialize when using full DNs
* Added :parent_class option to ldap_mapping which allows for object.parent() to return an instantiated object using the parent DN. (ldap_mapping :parent_class => String, ...)
* Fixed reconnect bug in Base#initialize (didn't respect infinite retries)
* Added(*) :timeout argument to allow timeouts on hanging LDAP connections
* Added(*) :retry_on_timeout boolean option to allow disabling retries on timeouts
* Added TimeoutError
* Added(*) a forking timeout using SIGALRM to interrupt handling.
* (*) Only works when RUBY_PLATFORM has "linux" in it

## 0.7.1

* Fix broken -W0 arg in activeldap.rb
* attribute_method=: '' and nil converted to ldap-pleasing [] values
* Added checks in write and search for connection down (to reconnect)
* Fixed broken idea of LDAP::err2string exceptions. Instead took errcodes from ldap.c in Ruby/LDAP.

## 0.7.0

* ConnectionError thrown from #initialize when there is no connection and retry limit was exceeded
* ConnectionError thrown when retries exceeded when no connection was created
* Separated connection types: SSL, TLS, and plain using :method
* Localized reconnect logic into Base.reconnect(force=false)
* Fixed password_block evaluation bug in do_bind() which broke SIMPLE re-binds and broke reconnect
* Add support for config[:sasl_quiet] in Base.connect
* (Delayed a case sensitivity patch for object classes and attributes due to weird errors)
* Add :retry_wait to Base.connect to determine the timeout before retrying a connection
* Fixed ActiveLDAP::Base.create_object() - classes were enclosed in quotes
* Added :ldap_scope Base.connect() argument to allow risk-seeking users to change the LDAP scope to something other than ONELEVEL.
* Cleaned up Configuration.rb to supply all default values for ActiveLDAP::Base.connect() and to use a constant instead of overriding class variables for no good reason.
* Added scrubbing for :base argument into Base.connect() to make sure a ' doesn't get evaluated.
* Refactored Base.connect(). It is now much cleaner and easier to follow.
* Moved schema retrieval to after bind in case a server requires privileges to access it.
* Reworked the bind process to be a little prettier. A lot of work to do here still.
* Added LDAP::err2exception(errno) which is the groundwork of a coming overhaul in user friendly error handling.
* Added support for Base::connect(.., :password => String, ...) to avoid stupid Proc.new {'foo'} crap
* Add :store_password option. When this is set, :password is not cleared and :password_block is not re-evaluated on each rebind.

## 0.6.0

* Disallow blank DN attribute values on initialization
* Fix bug reported by Maik Schmidt regarding object creation
* Added error checking to disallow DN attribute value changes
* Added AttributeAssignmentError (for above)
* Import() and initialize() no longer call attribute_method=()
* Added error condition if connection fails inside initialize()
* Changes examples and tests to use "dc=localdomain"
* has_many() entries no longer return nil when empty

## 0.5.9

* Change default base to dc=localdomain (as per Debian default).
* schema2.rb:attr() now returns [] instead of '' when empty.
* Lookup of new objects does not put dnattr()=value into the Base on lookup.
* Scope is now use ONELEVEL instead of SUBTREE as it broke object boundaries.
* Fixed @max_retries misuse.
* Added do_connect retries.
* Fixed find and find_all for the case - find_all('*').
* Fixed broken creation of objects from anonymous classes.
* Fixed broken use of ldap_mapping with anonymous classes.

## 0.5.8: Bugfix galore

* Allow nil "prefix"
* Fixed the dup bug with Anonymous patch.
* (maybe) Fixed stale connection problems by attempting reconn/bind.
* Hiding redefine warnings (for now)

## 0.5.7

* Fixed the @data.default = [] bug that daniel@nightrunner.com pointed out
  (and partially patched).

## 0.5.6

* Added support for foreign_key => 'dn' in has_many.

## 0.5.5

* Remove @@logger.debug entries during build
* Building -debug and regular gems and tarballs

## 0.5.4

* Added Base#import to streamline the Base.find and Base.find_all methods
  * Speeds up find and find_all by not accessing LDAP multiple times
   for data we already have.
* Added tests/benchmark which is a slightly modified version of excellent
  benchmarking code contributed by
  Ollivier Robert <roberto -_-AT-_- keltia.freenix.fr>.

## 0.5.3

* Changed attribute_method to send in associations
  * fixes belongs_to (with local_kay) and inheritance around that

## 0.5.2

* Make sure values are .dup'd when they come from LDAP

## 0.5.1

* Changed Schema2#class_attributes to return @{:must => [], :may => []}@
* Fixed Base#must and Base#may to return with full SUPerclass requirements

## 0.5.0

* API CHANGE (as with all 0.x.0 changes) (towards ActiveRecord duck typing)
  * Base#ldapattribute now always returns an array
  * Base#ldapattribute(true) now returns a dup of an array, string, etc 
   when appropriate (old default) - This is just for convenience
  * Base#ldapattribute returns the stored value, not just a .dup
  * Associations methods return objects by default instead of just names.
   Group.new('foo').members(false) will return names only.
  * Base.connect returns true as one might expect
* Value validation and changing (binary, etc) occur prior to write, and
  not immediately on attribute_method=(value).
* Attribute method validity is now determined /on-the-fly/.
* Default log level set to OFF speeds up 'speedtest' by 3 seconds! 
  (counters last point which added some slowness :)
* Added Schema2#class_attributes which caches and fully supertype expands
  attribute lists.
* Integrated Schema2#class_attributes with apply_objectclass which automagically
  does SUP traversal and automagically updates available methods on calls to
  #attributes, #method_missing, #validate, and #write
* Added 'attributes' to 'methods' allowing for irb autocompletion and other
  normal rubyisms
* Moved almost all validation to Base#validate to avoid unexpected exceptions
  being raised in seemingly unrelated method calls. This means that invalid 
  objectClasses may be specified. This will only be caught on #write or 
  a pre-emptive #validate. This goes for all attribute errors though.
  This also makes it possible to "break" objects by removing the 'top'
  objectclass and therefore the #objectClass method...

## 0.4.4

* Fixed binary subtype forcing:
  * was setting data as subtype ;binary even when not required
* Added first set of unit tests.
  * These will be cleaned up in later releases as more tests are added.
* Fixed subtype clobber non-subtype (unittest!)
  * cn and cn;lang-blah: the last loaded won
* Fixed multivalued subtypes from being shoved into a string (unittest!)
  * an error with attribute_input_value

## 0.4.3

* Fixed write (add) bugs introduced with last change
  * only bug fixes until unittests are in place

## 0.4.2

* Added ruby-activeldap.gemspec
* Integrated building a gem of 'ruby-activeldap' into Makefile.package
* Added attr parsing cache to speed up repetitive calls: approx 13x speedup
  * 100 usermod-binary-add calls

   <pre>
   !!!plain
   Without attr parsing cache:
     real    13m53.129s
     user    13m11.350s
     sys     0m7.030s
   With attr parsing cache:
     real    1m0.416s
     user    0m28.390s
     sys     0m2.380s
   </pre>

## 0.4.1:

* Schema2 was not correctly parsing objectClass entries.
  * This is fixed for now but must be revisited.

## 0.4.0

* Added #<attribute>(arrays) argument which when true
  always returns arrays. e.g.

  <pre>
  !!!plain
  irb> user.cn(true)
  => ['My Common Name']
  </pre>

  This makes things easier for larger programming tasks.
* Added subtype support:
  * Uses Hash objects to specify the subtype
   e.g. @user.userCertificate = {'binary' => File.read('mycert.der')}@
  * Added recursive type enforcement along with the subtype handling
  * This required overhauling the #write method.
    * Please report any problems ASAP! :^)
* Added automagic binary support
  * subtype wrapping done automatically
  * relies on X-NOT-HUMAN-READABLE flag
* Added LDAP::Schema2 which is an extension of Ruby/LDAP::Schema
  * made Schema#attr generic for easy type dereferencing
* Updated rdoc in activeldap.rb
* Updated examples (poorly) to reflect new functionality
* Added several private helper functions

## 0.3.6

* Fixed dn attribute value extraction on find and find_all
  * these may have grabbed the wrong value if a DN attr has
   multiple values.
* Fixed Base.search to return all values as arrays and update
  multivalued ones correctly
* Lowered the amount of default logging to FATAL only

## 0.3.5

* Moved to rubyforge.org!

## 0.3.4

* Changed license to Ruby's

## 0.3.3

* Changed Base.search to return an array instead of a hash of hashes
* Change Base.search to take in a hash as its arguments

## 0.3.2

* Bug fix - fixed support for module'd extension classes (again!)

## 0.3.1

* Updated the documentation
* Fixed ignoring of attrs argument in Base.search
* Fixed mistake in groupls (using dnattr directly)
* Fixed a mistake with overzealous dup'ing

## 0.3.0

* MORE API CHANGES (configuration.rb, etc)
* Major overhaul to the internals!
  * removed @@BLAH[@klass] in lieu of defining
   class methods which contain the required values. This
   allows for clean inheritance of Base subclasses! Whew!
  * Added @@config to store the options currently in use
   after a Base.connect
  * Now cache passwords for doing reconnects
  * dnattr now accessible to the outside as a class method only
* Added Base.search to wrap normal LDAP search for convenience.
  * This returns a hash of hashes with the results indexed first by
   full dn, then by attribute.

## 0.2.0

* API CHANGES:
  * Extension classes must be defined using map_to_ldap instead of setting
   random values in initialize
  * Base#find is now Base.find_all and is a class method
  * Base.find returns the first match a la Array#find
  * force_reload is gone in belongs_to and has_many created methods
  * hiding Base.new, Base.find, and Base.find_all from direct access
* added uniq to setting objectClass to avoid stupid errors
* fixed new object creation bug where attributes were added before the
  objectclass resulting in a violation (Base#write)
* fixed attribute dereferencing in Base#write
* fixed bug with .dup on Fixnums
* methods created by has_many/belongs_to  and find and find_all now take an
  optional argument dnattr_only which will return the value of dnattr for
  each result instead of a full object.
* Base.connection=(conn) added for multiplexing connections
* Added a manual to activeldap.rb which covers most usage of Ruby/ActiveLDAP
* Base.connect(:try_sasl => true) should now work with GSSAPI if you are
  using OpenLDAP >= 2.1.29

## 0.1.8

* .dup all returned attribute values to avoid weirdness
* .dup all assigned values to avoid weirdness
* Changed default configuration.rb to use example.com

## 0.1.7

* Added support for non-unique DN attributes
* Added authoritative DN retrieval with 'object.dn'

## 0.1.6

* Added Base.close method for clearing the existing connection (despite Ruby/LDAP's lack of .close)

## 0.1.5

* Fixed incorrect usage of @klass in .find (should .find be a class method?)

## 0.1.4

* Change WARN to INFO in associations.rb for has_many

## 0.1.3

* Fixed class name mangling
* Added support for classes to take DNs as the initialization value

## 0.1.2

* Patch from Dick Davies: Try SSL before TLS
* Log4r support
* Better packaging (automated)
* Work-around for SSL stupidity
  * SSLConn doesn't check if the port it connected to is really using SSL!

## 0.1.1

* Dynamic table class creation
* SASL/GSSAPI disabled by default - doesn't work consistently

## 0.1.0

* Added foreign_key to has_many
* Added local_key to belongs_to
* Added primary_members to Group example
* Added "nil" filtering to has_many
* Packaged up with setup.rb
* Added RDocs and better comments

## 0.0.9

* Separated extension classes from ActiveLDAP module
* Cleaned up examples with new requires

## 0.0.8

* Added user and group scripting examples
  * usermod, userls, useradd, userdel
  * groupmod, groupls

## 0.0.7

* Cleaner authentication loop:
  * SASL (GSSAPI only), simple, anonymous
* Added allow_anonymous option added (default: false)

## 0.0.6

* Write support cleaned up
* Exception classes added

## 0.0.5

* LDAP write support added

## 0.0.4

* MUST and MAY data validation against schema using objectClasses

## 0.0.3

* LDAP attributes alias resolution and data mapping

## 0.0.2

* Associations: has_many and belongs_to Class methods added for Base

## 0.0.1

* Extension approach in place with example User and Group classes

## 0.0.0

* Basic LDAP read support in place with hard-coded OUs
