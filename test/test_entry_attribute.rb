# -*- coding: utf-8 -*-

require "al-test-utils"

class TestEntryAttribute < Test::Unit::TestCase
  include AlTestUtils

  class TestExist < self
    priority :must
    def test_existence
      schema = ActiveLdap::Base.connection.schema
      object_classes = ["posixAccount"]
      entry_attribute = ActiveLdap::EntryAttribute.new(schema, object_classes)
      assert_true(entry_attribute.exist?("cn"))
    end

    def test_non_existence
      schema = nil
      object_classes = []
      entry_attribute = ActiveLdap::EntryAttribute.new(schema, object_classes)
      assert_false(entry_attribute.exist?("nonExistence"))
    end
  end
end
