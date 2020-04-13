# ActiveLdap

A ruby library for object-oriented LDAP interface.

* Copyright (C) 2004-2006 Will Drewry <will@alum.bu.edu>
* Copyright (C) 2006-2020 Sutou Kouhei <kou@clear-code.com>

## Description

'ActiveLdap' is a ruby library which provides a clean
objected oriented interface to LDAP library.  It was
inspired by ActiveRecord. This is not nearly as clean or as
flexible as ActiveRecord, but it is still trivial to define
new objects and manipulate them with minimal difficulty.

For example and usage - read the
[document](https://activeldap.github.io/).

## Prerequisites

### Ruby interpreter

  * [Ruby](https://www.ruby-lang.org)
  * [JRuby](https://www.jruby.org/)

See the above links for installation.

### LDAP client

JRuby doesn't need to install new library because JRuby has builtin
LDAP support. Ruby users need one of them:

* [Ruby/LDAP](https://rubygems.org/gems/ruby-ldap)
* [Net::LDAP](https://rubygems.org/gems/net-ldap)

See the above links for installation.

### Active Model

A toolkit for building modeling frameworks like Active Record and
Active Resource.

## Rails

See [Rails](file.rails.html)
([doc/text/rails.textile](doc/text/rails.md) in the repository and on
GitHub) page for Rails integration.

## License

This program is free software; you can redistribute it and/or modify it.  It is
dual licensed under Ruby's license and under the terms of the GNU General
Public License as published by the Free Software Foundation; either version 2,
or (at your option) any later version.

Please see the file LICENSE for the terms of the license.

## Thanks

This list may not be correct. If you notice mistakes of this
list, please point out.

* Dick Davies
* Nathan Kinder
* Patrick Cole
* Google Inc.
* Nobody: Bug reports and API improveent ideas.
* James Hughes: Bug reports and advices and documentations.
* Buzz Chopra: Documentations.
* Christoph Lipp:
  * Bug reports.
  * Tell us character escape syntax.
* Jeff Hall: Bug reports.
* Ernie Miller: Bug reports and advices.
* Daniel Pfile: Patches.
* Jacob Wilkins: Bug reports.
* Ace Suares:
  * Bug reports.
  * Nederlands translations.
* Iain Pople: Bug reports and API improvement ideas.
* Kevin McCarthy: Patches.
* Perry Smith: Patches, bug reports and indications.
* Marc Dequènes: API suggestions.
* Jeremy Pruitt: Bug reports.
* Bodaniel Jeanes:
  * A suggestion for behavior on simple bind with empty password.
  * Bug reports.
* Naoto Morishima: Bug reports.
* David Morton:
  * An API improvement idea.
  * Bug reports.
* Lennon Day-Reynolds: Bug reports.
* Tilo: A bug report.
* Matt Mencel: Bug reports.
* CultureSpy:
  * Bug reports.
  * Bug fixes.
* gwarf12: A bug report.
* Baptiste Grenier: API improvement ideas.
* Richard 3 Nicholas: API improvement ideas.
* Kazuhiro NISHIYAMA: A bug report.
* Grzegorz Marszałek: A bug report.
* しまさわらさん: A suggesetion.
* Ted Lepich: A suggestion.
* danger1986: A suggestion.
* michael.j.konopka: Bug reports.
* ingersoll: A suggestion.
* Alexey.Chebotar: Bug reports.
* ery.lee: A bug report.
* id:dicdak: A bug report.
* Raiko Mitsu: A bug report.
* Kazuaki Takase: Documents in Japanese.
* Tim Hermans: A bug report.
* Joe Francis: A suggestion.
* Tiago Fernandes: Bug reports.
* achemze: A suggestion.
* George Montana Harkin: A suggestion.
* Marc Dequènes: Bug reports.
* brad@lucky-dip.net: A bug report.
* Hideyuki Yasuda: Bug reports.
* zachwily: A bug report.
* syrius.ml@no-log.org: A bug report.
* Tim Hermans: A bug report.
* Anthony M. Martinez: Helped SASL options support
* ilusi0n.x: A bug report.
* projekttabla: A suggestion.
* christian.pennaforte: A bug report.
* planetmcd: A bug report.
* spoidar: Rails 3 support.
* Kris Wehner: Rails 2.3.8 support.
* Ryan Tandy:
  * A test bug fix.
  * Rails 3 support.
* rbq: A bug report.
* Narihiro Nakamura: Rails 3 support.
* Hidetoshi Yoshimoto: Rails 3 support.
* warden: A bug report.
* bklier: A bug fix.
* Craig White: Bug reports.
