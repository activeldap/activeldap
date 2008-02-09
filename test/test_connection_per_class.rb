require 'al-test-utils'

class TestConnectionPerClass < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  priority :normal
  def test_multi_establish_connections
    make_ou("Sub")
    make_ou("Sub2")
    sub_class = ou_class("ou=Sub")
    sub2_class = ou_class("ou=Sub2")

    configuration = current_configuration.symbolize_keys
    configuration[:scope] = :base
    current_base = configuration[:base]
    sub_configuration = configuration.dup
    sub_base = "ou=Sub,#{current_base}"
    sub_configuration[:base] = sub_base
    sub2_configuration = configuration.dup
    sub2_base = "ou=Sub2,#{current_base}"
    sub2_configuration[:base] = sub2_base

    sub_class.establish_connection(sub_configuration)
    sub_class.prefix = nil
    sub2_class.establish_connection(sub2_configuration)
    sub2_class.prefix = nil

    assert_equal([sub_base], sub_class.find(:all).collect(&:dn))
    assert_equal([sub2_base], sub2_class.find(:all).collect(&:dn))
    assert_equal([sub_base], sub_class.find(:all).collect(&:dn))
    assert_equal([sub2_base], sub2_class.find(:all).collect(&:dn))
  end

  def test_bind
    non_anon_class = ou_class("ou=NonAnonymous")
    anon_class = ou_class("ou=Anonymous")

    assert(non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)

    anon_class.connection.unbind
    assert(!non_anon_class.connection.bound?)
    assert(!anon_class.connection.bound?)

    anon_class.connection.rebind
    assert(non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)

    assert_raises(ActiveLdap::AuthenticationError) do
      connect(non_anon_class,
              :bind_dn => nil,
              :allow_anonymous => false,
              :retry_limit => 0)
    end

    assert(!non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)

    anon_class.connection.unbind
    assert(!non_anon_class.connection.bound?)
    assert(!anon_class.connection.bound?)

    anon_class.connection.rebind
    assert(!non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)

    anon_class.connection.unbind
    assert(!non_anon_class.connection.bound?)
    assert(!anon_class.connection.bound?)

    assert_nothing_raised do
      connect(anon_class,
              :bind_dn => nil,
              :allow_anonymous => true)
    end

    assert(!non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)
  end

  private
  def connect(klass, config)
    klass.establish_connection({:adapter => adapter}.merge(config))
    klass.connection.connect
  end
end
