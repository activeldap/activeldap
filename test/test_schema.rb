require 'al-test-utils'

class SchemaTest < Test::Unit::TestCase
  def test_name_as_key
    top_schema = "( 2.5.6.0 NAME 'top' DESC 'top of the superclass chain' " +
                 "ABSTRACT MUST objectClass )"
    expect = {
      :name => ["top"],
      :desc => ['top of the superclass chain'],
      :abstract => ["TRUE"],
      :must => ["objectClass"]
    }
    assert_schema(expect, "2.5.6.0", top_schema)
    assert_schema(expect, "top", top_schema)
  end

  def test_name_as_key_for_multiple_name
    uid_schema = "( 0.9.2342.19200300.100.1.1 NAME ( 'uid' 'userid' ) " +
                 "DESC 'RFC1274: user identifier' EQUALITY caseIgnoreMatch " +
                 "SUBSTR caseIgnoreSubstringsMatch " +
                 "SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{256} )"

    expect = {
      :name => ["uid", "userid"],
      :desc => ['RFC1274: user identifier'],
      :equality => ["caseIgnoreMatch"],
      :substr => ["caseIgnoreSubstringsMatch"],
      :syntax => ["1.3.6.1.4.1.1466.115.121.1.15{256}"],
    }
    assert_schema(expect, "0.9.2342.19200300.100.1.1", uid_schema)
    assert_schema(expect, "uid", uid_schema)
    assert_schema(expect, "userid", uid_schema)
  end

  def test_dollar
    dn_match_schema = "( 2.5.13.1 NAME 'distinguishedNameMatch' APPLIES " +
                      "( creatorsName $ modifiersName $ subschemaSubentry " +
                      "$ namingContexts $ aliasedObjectName $ " +
                      "distinguishedName $ seeAlso $ olcDefaultSearchBase $ " +
                      "olcRootDN $ olcSchemaDN $ olcSuffix $ olcUpdateDN $ " +
                      "member $ owner $ roleOccupant $ manager $ " +
                      "documentAuthor $ secretary $ associatedName $ " +
                      "dITRedirect ) )"

    expect = {
      :name => ["distinguishedNameMatch"],
      :applies => %w(creatorsName modifiersName subschemaSubentry
                     namingContexts aliasedObjectName
                     distinguishedName seeAlso olcDefaultSearchBase
                     olcRootDN olcSchemaDN olcSuffix olcUpdateDN
                     member owner roleOccupant manager
                     documentAuthor secretary associatedName
                     dITRedirect),
    }
    assert_schema(expect, "2.5.13.1", dn_match_schema)
    assert_schema(expect, "distinguishedNameMatch", dn_match_schema)
  end

  def test_dc_object
    dc_object_schema = "( 1.3.6.1.4.1.1466.344 NAME 'dcObject' DESC " +
                       "'RFC2247: domain component object' SUP top " +
                       "AUXILIARY MUST dc )"

    expect = {
      :name => ["dcObject"],
      :desc => ['RFC2247: domain component object'],
      :auxiliary => ["TRUE"],
      :must => ["dc"],
    }
    assert_schema(expect, "1.3.6.1.4.1.1466.344", dc_object_schema)
    assert_schema(expect, "dcObject", dc_object_schema)
  end

  def test_organization
    organization_schema = "( 2.5.6.4 NAME 'organization' DESC " +
                          "'RFC2256: an organization' SUP top STRUCTURAL " +
                          "MUST o MAY ( userPassword $ searchGuide $ " +
                          "seeAlso $ businessCategory $ x121Address $ " +
                          "registeredAddress $ destinationIndicator $ " +
                          "preferredDeliveryMethod $ telexNumber $ " +
                          "teletexTerminalIdentifier $ telephoneNumber $ " +
                          "internationaliSDNNumber $ " +
                          "facsimileTelephoneNumber $ street $ " +
                          "postOfficeBox $ postalCode $ postalAddress $ " +
                          "physicalDeliveryOfficeName $ st $ l $ " +
                          "description ) )"

    expect = {
      :name => ["organization"],
      :desc => ['RFC2256: an organization'],
      :sup => ["top"],
      :structural => ["TRUE"],
      :must => ["o"],
      :may => %w(userPassword searchGuide seeAlso businessCategory
                 x121Address registeredAddress destinationIndicator
                 preferredDeliveryMethod telexNumber
                 teletexTerminalIdentifier telephoneNumber
                 internationaliSDNNumber
                 facsimileTelephoneNumber street
                 postOfficeBox postalCode postalAddress
                 physicalDeliveryOfficeName st l description),
    }
    assert_schema(expect, "2.5.6.4", organization_schema)
    assert_schema(expect, "organization", organization_schema)
  end

  def test_posix_account
    posix_account_schema = "( 1.3.6.1.1.1.2.0 NAME 'posixAccount' DESC " +
                           "'Abstraction of an account with POSIX " +
                           "attributes' SUP top AUXILIARY MUST ( cn $ " +
                           "uid $ uidNumber $ gidNumber $ homeDirectory " +
                           ") MAY ( userPassword $ loginShell $ gecos $ " +
                           "description ) )"
    expect = {
      :name => ["posixAccount"],
      :desc => ['Abstraction of an account with POSIX attributes'],
      :sup => ["top"],
      :auxiliary => ["TRUE"],
      :must => %w(cn uid uidNumber gidNumber homeDirectory),
      :may => %w(userPassword loginShell gecos description),
    }
    assert_schema(expect, "1.3.6.1.1.1.2.0", posix_account_schema)
    assert_schema(expect, "posixAccount", posix_account_schema)
  end

  def test_jpeg_photo
    jpeg_photo_schema = "( 0.9.2342.19200300.100.1.60 NAME 'jpegPhoto' " +
                        "DESC 'RFC2798: a JPEG image' SYNTAX " +
                        "1.3.6.1.4.1.1466.115.121.1.28 )"
    expect = {
      :name => ["jpegPhoto"],
      :desc => ['RFC2798: a JPEG image'],
      :syntax => ["1.3.6.1.4.1.1466.115.121.1.28"],
    }
    assert_schema(expect, "0.9.2342.19200300.100.1.60", jpeg_photo_schema)
    assert_schema(expect, "jpegPhoto", jpeg_photo_schema)

    jpeg_schema = "( 1.3.6.1.4.1.1466.115.121.1.28 DESC 'JPEG' " +
                  "X-NOT-HUMAN-READABLE 'TRUE' )"

    expect = {
      :desc => ['JPEG'],
      :x_not_human_readable => ["TRUE"],
    }
    assert_schema(expect, "1.3.6.1.4.1.1466.115.121.1.28", jpeg_schema)

    schema = ActiveLDAP::Schema.new({"attributeTypes" => [jpeg_photo_schema],
                                     "ldapSyntaxes" => [jpeg_schema]})
    assert(schema.binary?("jpegPhoto"))
  end

  private
  def assert_schema(expect, name, schema)
    sub = "objectClass"
    entry = {sub => [schema]}
    schema = ActiveLDAP::Schema.new(entry)
    actual = {}
    normalized_expect = {}
    expect.each do |key, value|
      normalized_key = key.to_s.gsub(/_/, "-")
      normalized_expect[normalized_key] = value
      actual[normalized_key] = schema.attr(sub, name, normalized_key)
    end
    assert_equal(normalized_expect, actual)
  end
end
