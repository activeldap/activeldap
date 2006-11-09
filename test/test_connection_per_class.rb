require 'al-test-utils'

class ConnectionPerClassTest < Test::Unit::TestCase
  include AlTestUtils

  def test_bind
    non_anon_class = ou_class("ou=NonAnonymous")
    anon_class = ou_class("ou=Anonymous")

    assert(non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)

    anon_class.connection.unbind
    assert(!non_anon_class.connection.bound?)
    assert(!anon_class.connection.bound?)

    anon_class.connection.bind
    assert(non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)

    assert_raises(ActiveLdap::AuthenticationError) do
      non_anon_class.establish_connection(:bind_format => nil,
                                          :allow_anonymous => false,
                                          :retry_limit => 0)
    end

    assert(!non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)

    anon_class.connection.unbind
    assert(!non_anon_class.connection.bound?)
    assert(!anon_class.connection.bound?)

    anon_class.connection.bind
    assert(!non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)

    anon_class.connection.unbind
    assert(!non_anon_class.connection.bound?)
    assert(!anon_class.connection.bound?)

    assert_nothing_raised do
      anon_class.establish_connection(:bind_format => nil,
                                      :allow_anonymous => true)
    end

    assert(!non_anon_class.connection.bound?)
    assert(anon_class.connection.bound?)
  end
end
