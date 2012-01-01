Gem::Specification.new do |gem|
    gem.name    = 'activeldap'
    gem.version = '3.1.1'
    gem.date    = Date.today.to_s

    gem.summary = "Using LDAP like ActiveRecord"
    gem.description = "extended description"

    gem.authors  = ['Kouhei Sutou', 'Will Drewry']
    gem.email    = 'kou@clear-code.com'
    gem.homepage = 'http://github.com/activeldap/activeldap'

    gem.add_dependency('activemodel', '>= 3.1.0.rc4')
    gem.add_dependency('locale')
    gem.add_dependency('fast_gettext')
    gem.add_dependency('gettext_i18n_rails')

    gem.add_development_dependency('rspec', [">= 2.0.0"])
    gem.add_development_dependency('ruby-ldap')
    gem.add_development_dependency('net-ldap')
    gem.add_development_dependency('jeweler')
    gem.add_development_dependency('test-unit')
    gem.add_development_dependency('test-unit-notify')
    gem.add_development_dependency('yard')
    gem.add_development_dependency('RedCloth')

    # ensure the gem is built out of versioned files
    gem.files = Dir['Rakefile', '{lib,man,test,spec}/**/*',
        'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
end
