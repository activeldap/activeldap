require 'al-test-utils'

class TestUser < Test::Unit::TestCase
  include AlTestUtils

  # This adds all required attributes and writes
  def test_add
    ensure_delete_user("test-user") do |uid|
      user = @user_class.new(uid)

      assert(user.new_entry?, "#{uid} must not exist in LDAP prior to testing")

      assert_equal(['posixAccount', 'person'].sort, user.classes.sort,
                   "Class User's ldap_mapping should specify " +
                   "['posixAccount', 'person']. This was not returned.")

      user.add_class('posixAccount', 'shadowAccount',
                     'person', 'inetOrgPerson', 'organizationalPerson')

      cn = 'Test User (Default Language)'
      user.cn = cn
      assert_equal(cn, user.cn, 'user.cn should have returned "#{cn}"')

      # test force_array
      assert_equal([cn], user.cn(true),
                   'user.cn(true) should have returned "[#{cn}]"')

      cn = {'lang-en-us' => 'Test User (EN-US Language)'}
      user.cn = cn
      # Test subtypes
      assert_equal(cn, user.cn, 'user.cn should match')

      cn = ['Test User (Default Language)',
            {'lang-en-us' => ['Test User (EN-US Language)', 'Foo']}]
      user.cn = cn
      # Test multiple entries with subtypes
      assert_equal(cn, user.cn,
                   'This should have returned an array of a ' +
                   'normal cn and a lang-en-us cn.')

      uid_number = "9000"
      user.uid_number = uid_number
      assert_equal(uid_number.to_i, user.uid_number)
      assert_equal(uid_number, user.uid_number_before_type_cast)

      gid_number = 9000
      user.gid_number = gid_number
      assert_equal(gid_number, user.gid_number)
      assert_equal(gid_number, user.gid_number_before_type_cast)

      home_directory = '/home/foo'
      user.home_directory = home_directory
      # just for sanity's sake
      assert_equal(home_directory, user.home_directory,
                   'This should be #{home_directory.dump}.')
      assert_equal([home_directory], user.home_directory(true),
                   'This should be [#{home_directory.dump}].')

      see_also = "cn=XXX,dc=local,dc=net"
      user.see_also = see_also
      assert_equal(ActiveLdap::DN.parse(see_also), user.see_also)

      see_also = ActiveLdap::DN.parse(see_also)
      user.see_also = see_also
      assert_equal(see_also, user.see_also)

      assert(!user.valid?)
      assert(user.errors.invalid?(:sn))
      errors = %w(person organizationalPerson
                  inetOrgPerson).collect do |object_class|
        if ActiveLdap.get_text_supported?
          format = _("%{fn} is required attribute by objectClass '%s': " \
                     "aliases: %s")
          format = user.gettext(format)
          format = format % {:fn => user.class.human_attribute_name("sn")}
          format % [user.class.human_object_class_name(object_class),
                    user.class.human_attribute_name("surname")]
        else
          format = "is required attribute by objectClass '%s': aliases: %s"
          user.gettext(format) % [object_class, "surname"]
        end
      end
      assert_equal(errors.sort, user.errors.on(:sn).sort)
      user.sn = ['User']
      assert(user.valid?)
      assert_equal(0, user.errors.size)

      assert_nothing_raised {user.save!}

      user.user_certificate = certificate
      user.jpeg_photo = jpeg_photo

      assert(ActiveLdap::Base.schema.attribute('jpegPhoto').binary?,
             'jpegPhoto is binary?')

      assert(ActiveLdap::Base.schema.attribute('userCertificate').binary?,
             'userCertificate is binary?')
      assert_nothing_raised {user.save!}
    end
  end


  # This tests the reload of a binary_required type
  def test_binary_required
    require 'openssl'
    make_temporary_user do |user, password|
      # validate add
      user.user_certificate = nil
      assert_nil(user.user_certificate)
      assert_nothing_raised() { user.save! }
      assert_nil(user.user_certificate)

      user.user_certificate = {"binary" => [certificate]}
      assert_equal(certificate, user.user_certificate)
      assert_nothing_raised() { user.save! }
      assert_equal(certificate, user.user_certificate)

      # now test modify
      user.user_certificate = nil
      assert_nil(user.user_certificate)
      assert_nothing_raised() { user.save! }
      assert_nil(user.user_certificate)

      user.user_certificate = certificate
      assert_equal(certificate, user.user_certificate)
      assert_nothing_raised() { user.save! }

      # validate modify
      user = @user_class.find(user.uid)
      assert_equal(certificate, user.user_certificate)

      expected_cert = OpenSSL::X509::Certificate.new(certificate)
      actual_cert = user.user_certificate
      actual_cert = OpenSSL::X509::Certificate.new(actual_cert)
      assert_equal(expected_cert.subject.to_s,
                   actual_cert.subject.to_s,
                   'Cert must parse correctly still')
    end
  end

  def test_binary_required_nested
    make_temporary_user do |user, password|
      user.user_certificate = {"lang-en" => [certificate]}
      assert_equal({'lang-en' => certificate},
                   user.user_certificate)
      assert_nothing_raised() { user.save! }
      assert_equal({'lang-en' => certificate},
                   user.user_certificate)
    end
  end

  # This tests the reload of a binary type (not forced!)
  def test_binary
    make_temporary_user do |user, password|
      # reload and see what happens
      assert_equal(jpeg_photo, user.jpeg_photo,
                   "This should have been equal to #{jpeg_photo_path.dump}")

      # now test modify
      user.jpeg_photo = nil
      assert_nil(user.jpeg_photo)
      assert_nothing_raised() { user.save! }
      assert_nil(user.jpeg_photo)

      user.jpeg_photo = jpeg_photo
      assert_equal(jpeg_photo, user.jpeg_photo)
      assert_nothing_raised() { user.save! }

      # now validate modify
      user = @user_class.find(user.uid)
      assert_equal(jpeg_photo, user.jpeg_photo)
    end
  end

  # This tests the removal of a objectclass
  def test_remove_object_class
    make_temporary_user do |user, password|
      assert_nil(user.shadow_max,
                 'Should get the default nil value for shadowMax')

      # Remove shadowAccount
      user.remove_class('shadowAccount')
      assert(user.valid?)
      assert_nothing_raised() { user.save! }

      assert_raise(NoMethodError,
                   'shadowMax should not be defined anymore' ) do
        user.shadow_max
      end
    end
  end


  # Just modify a few random attributes
  def test_modify_with_subtypes
    make_temporary_user do |user, password|
      cn = ['Test User', {'lang-en-us' => ['Test User', 'wad']}]
      user.cn = cn
      assert_nothing_raised() { user.save! }

      user = @user_class.find(user.uid)
      assert_equal(cn, user.cn,
                   'Making sure a modify with mixed subtypes works')
    end
  end

  # This tests some invalid input handling
  def test_invalid_input
  end

  # This tests deletion
  def test_destroy
    make_temporary_user do |user, password|
      user.destroy
      assert(user.new_entry?, 'user should no longer exist')
    end
  end
end
