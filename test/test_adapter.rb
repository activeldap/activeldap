require 'al-test-utils'

class TestAdapter < Test::Unit::TestCase
  include AlTestUtils

  def setup
  end

  def teardown
  end

  priority :must
  def test_operator
    assert_parse_filter("(uid~=Alice)", ["uid", "~=", "Alice"])
    assert_parse_filter("(&(uid~=Alice)(uid~=Bob))",
                        ["uid", "~=", "Alice", "Bob"])
    assert_parse_filter("(uid~=Alice)", [["uid", "~=", "Alice"]])
    assert_parse_filter("(|(uid~=Alice)(uid~=Bob))",
                        [:or,
                         ["uid", "~=", "Alice"],
                         ["uid", "~=", "Bob"]])
    assert_parse_filter("(|(uid~=Alice)(uid~=Bob))",
                        [:or,
                         ["uid", "~=", "Alice", "Bob"]])
  end

  priority :normal
  def test_filter_with_escaped_character
    assert_parse_filter("(uid=Alice\\28Bob)", {:uid => "Alice(Bob"})
    assert_parse_filter("(uid=Alice\\29Bob)", {:uid => "Alice)Bob"})
    assert_parse_filter("(uid=Alice\\29Bob\\28)", {:uid => "Alice)Bob("})
    assert_parse_filter("(uid=Alice\\28\\29Bob)", {:uid => "Alice()Bob"})
    assert_parse_filter("(uid=Alice*Bob)", {:uid => "Alice*Bob"})
    assert_parse_filter("(uid=Alice\\2ABob)", {:uid => "Alice**Bob"})
    assert_parse_filter("(uid=Alice\\2A*\\5CBob)", {:uid => "Alice***\\Bob"})
    assert_parse_filter("(uid=Alice\\5C\\2A*Bob)", {:uid => "Alice\\***Bob"})
  end

  def test_empty_filter
    assert_parse_filter(nil, nil)
    assert_parse_filter(nil, "")
    assert_parse_filter(nil, "   ")
  end

  def test_simple_filter
    assert_parse_filter("(objectClass=*)", "objectClass=*")
    assert_parse_filter("(objectClass=*)", "(objectClass=*)")
    assert_parse_filter("(&(uid=bob)(objectClass=*))",
                        "(&(uid=bob)(objectClass=*))")

    assert_parse_filter("(objectClass=*)", {:objectClass => "*"})
    assert_parse_filter("(&(objectClass=*)(uid=bob))",
                        {:uid => "bob", :objectClass => "*"})

    assert_parse_filter("(&(uid=bob)(objectClass=*))",
                        [:and, "uid=bob", "objectClass=*"])
    assert_parse_filter("(&(uid=bob)(objectClass=*))",
                        [:&, "uid=bob", "objectClass=*"])
    assert_parse_filter("(|(uid=bob)(objectClass=*))",
                        [:or, "uid=bob", "objectClass=*"])
    assert_parse_filter("(|(uid=bob)(objectClass=*))",
                        [:|, "uid=bob", "objectClass=*"])
  end

  def test_multi_value_filter
    assert_parse_filter("(&(objectClass=top)(objectClass=posixAccount))",
                        {:objectClass => ["top", "posixAccount"]})

    assert_parse_filter("(&(objectClass=top)(objectClass=posixAccount))",
                        [[:objectClass, "top"],
                         [:objectClass, "posixAccount"]])
    assert_parse_filter("(&(objectClass=top)(objectClass=posixAccount))",
                        [[:objectClass, ["top", "posixAccount"]]])
  end

  def test_nested_filter
    assert_parse_filter("(&(objectClass=*)(uid=bob))",
                        [:and, {:uid => "bob", :objectClass => "*"}])
    assert_parse_filter("(&(objectClass=*)(|(uid=bob)(uid=alice)))",
                        [:and, {:objectClass => "*"},
                         [:or, [:uid, "bob"], [:uid, "alice"]]])
    assert_parse_filter("(&(objectClass=*)(|(uid=bob)(uid=alice)))",
                        [:and,
                         {:objectClass => "*",
                          :uid => [:or, "bob", "alice"]}])
    assert_parse_filter("(&(gidNumber=100001)" +
                        "(|(uid=temp-user1)(uid=temp-user2)))",
                        [:and,
                         [:and, {"gidNumber" => ["100001"]}],
                         [:or, {"uid" => ["temp-user1", "temp-user2"]}]])
    assert_parse_filter("(&(gidNumber=100001)" +
                        "(objectClass=person)(objectClass=posixAccount))",
                        [:and,
                         [:or, ["gidNumber", "100001"]],
                         ["objectClass", "person"],
                         ["objectClass", "posixAccount"]])
    assert_parse_filter("(&(!(|(gidNumber=100001)(gidNumber=100002)))" +
                        "(objectClass=person)(!(objectClass=posixAccount)))",
                        [:and,
                         [:not, [:or, ["gidNumber", "100001", "100002"]]],
                         ["objectClass", "person"],
                         [:not, ["objectClass", "posixAccount"]]])
  end

  def test_invalid_operator
    assert_raises(ArgumentError) do
      assert_parse_filter("(&(objectClass=*)(uid=bob))",
                          [:xxx, {:uid => "bob", :objectClass => "*"}])
    end
  end

  private
  def assert_parse_filter(expected, filter)
    adapter = ActiveLdap::Adapter::Base.new
    assert_equal(expected, adapter.send(:parse_filter, filter))
  end
end
