require 'al-test-utils'

class UserTest < Test::Unit::TestCase
  include AlTestUtils

  # This adds all required attributes and writes
  def test_add
    ensure_delete_user("test-user") do |uid|
      user = @user_class.new(uid)

      assert_equal(false, user.exists?,
                   "#{uid} must not exist in LDAP prior to testing")

      assert_equal(['posixAccount', 'person'].sort, user.classes.sort,
                   "Class User's ldap_mapping should specify " +
                   "['posixAccount', 'person']. This was not returned.")

      user.add_class('posixAccount', 'shadowAccount',
                     'person', 'inetOrgPerson', 'organizationalPerson')

      cn = 'Test User (Default Language)'
      user.cn = cn
      assert_equal(cn, user.cn, 'user.cn should have returned "#{cn}"')

      # test not_array
      assert_equal([cn], user.cn(false), 'user.cn should have returned "#{cn}"')

      cn = {'lang-en-us' => 'Test User (EN-US Language)'}
      user.cn = cn
      assert_raise(ActiveLDAP::AttributeEmpty) { user.validate }
      # Test subtypes
      assert_equal(cn, user.cn, 'user.cn should match')

      cn = ['Test User (Default Language)',
            {'lang-en-us' => ['Test User (EN-US Language)', 'Foo']}]
      user.cn = cn
      assert_raise(ActiveLDAP::AttributeEmpty) { user.validate }
      # Test multiple entries with subtypes
      assert_equal(cn, user.cn,
                   'This should have returned an array of a ' +
                   'normal cn and a lang-en-us cn.')

      assert_raise(ActiveLDAP::AttributeEmpty,
                   'This should have raised an error!') do
        user.validate
      end

      uid_number = 9000
      user.uidNumber = uid_number
      # Test to_s on Fixnums
      assert_equal(uid_number.to_s, user.uidNumber,
                   'uidNumber did not get set correctly.')
      assert_raise(ActiveLDAP::AttributeEmpty) { user.validate }
      assert_equal([uid_number.to_s], user.uidNumber(false),
                   'uidNumber did not get changed to an array by #validate().')

      gid_number = 9000
      user.gidNumber = gid_number
      # Test to_s on Fixnums
      assert_equal(gid_number.to_s, user.gidNumber,
                   'gidNumber did not get set correctly.')
      assert_raise(ActiveLDAP::AttributeEmpty) { user.validate }
      assert_equal([gid_number.to_s], user.gidNumber(false),
                   'not_array argument failed')

      home_directory = '/home/foo'
      user.homeDirectory = home_directory
      # just for sanity's sake
      assert_equal(home_directory, user.homeDirectory,
                   'This should be [#{home_directory.dump}].')
      assert_raise(ActiveLDAP::AttributeEmpty) { user.validate }
      assert_equal(home_directory, user.homeDirectory(true),
                   'This should be #{home_directory.dump}.')


      user.sn = ['User']

      user.userCertificate = certificate
      user.jpegPhoto = jpeg_photo
      assert_nothing_raised {user.validate}

      assert(ActiveLDAP::Base.schema.binary?('jpegPhoto'),
             'jpegPhoto is binary?')

      assert(ActiveLDAP::Base.schema.binary?('userCertificate'),
             'userCertificate is binary?')

      assert_nothing_raised { user.write }
    end
  end


  # This tests the reload of a binary_required type
  def test_binary_required
    make_temporary_user do |user, password|
      # validate add
      assert_equal({'binary' => [certificate]},
                   user.userCertificate,
                   'This should have been forced to be a binary subtype.')

      # now test modify
      user.userCertificate = ''
      assert_nothing_raised() { user.write }

      user.userCertificate = certificate
      assert_nothing_raised() { user.write }

      # validate modify
      user = @user_class.find(user.uid(true))
      assert_equal({'binary' => [certificate]},
                   user.userCertificate,
                   'This should have been forced to be a binary subtype.')

      expected_cert = OpenSSL::X509::Certificate.new(certificate)
      actual_cert = user.userCertificate['binary'][0]
      actual_cert = OpenSSL::X509::Certificate.new(actual_cert)
      assert_equal(expected_cert.subject.to_s,
                   actual_cert.subject.to_s,
                   'Cert must parse correctly still')
    end
  end

  # This tests the reload of a binary type (not forced!)
  def test_binary
    make_temporary_user do |user, password|
      # reload and see what happens
      assert_equal(jpeg_photo, user.jpegPhoto,
                   "This should have been equal to #{jpeg_photo_path.dump}")

      # now test modify
      user.jpegPhoto = ''
      assert_nothing_raised() { user.write }
      user.jpegPhoto = jpeg_photo
      assert_nothing_raised() { user.write }

      # now validate modify
      user = @user_class.find(user.uid(true))
      assert_equal(jpeg_photo, user.jpegPhoto,
                   "This should have been equal to #{jpeg_photo_path.dump}")
    end
  end

  # This tests the removal of a objectclass
  def test_remove_object_class
    make_temporary_user do |user, password|
      assert_equal(nil, user.shadowMax,
                   'Should get the default nil value for shadowMax')

      # Remove shadowAccount
      user.remove_class('shadowAccount')
      assert_nothing_raised() { user.validate }
      assert_nothing_raised() { user.write }

      assert_raise(NoMethodError,
                   'shadowMax should not be defined anymore' ) do
        user.shadowMax
      end
    end
  end


  # Just modify a few random attributes
  def test_modify_with_subtypes
    make_temporary_user do |user, password|
      cn = ['Test User', {'lang-en-us' => ['Test User', 'wad']}]
      user.cn = cn
      assert_nothing_raised() { user.write }

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
      assert(!user.exists?, 'user should no longer exist')
    end
  end
end
