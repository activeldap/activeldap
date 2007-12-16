require 'al-test-utils'

class TestConnectionPerClass < Test::Unit::TestCase
  include AlTestUtils

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
