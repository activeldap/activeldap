require 'al-test-utils'

class TestSchema < Test::Unit::TestCase
  priority :must
  def test_attribute_name_with_under_score
    top_schema =
      "( 2.5.6.0 NAME 'Top' STRUCTURAL MUST objectClass MAY ( " +
      "cAPublicKey $ cAPrivateKey $ certificateValidityInterval $ " +
      "authorityRevocation $ lastReferencedTime $ " +
      "equivalentToMe $ ACL $ backLink $ binderyProperty $ " +
      "Obituary $ Reference $ revision $ " +
      "ndsCrossCertificatePair $ certificateRevocation $ " +
      "usedBy $ GUID $ otherGUID $ DirXML-Associations $ " +
      "creatorsName $ modifiersName $ unknownBaseClass $ " +
      "unknownAuxiliaryClass $ auditFileLink $ " +
      "masvProposedLabelel $ masvDefaultRange $ " +
      "masvAuthorizedRange $ objectVersion $ " +
      "auxClassCompatibility $ rbsAssignedRoles $ " +
      "rbsOwnedCollections $ rbsAssignedRoles2 $ " +
      "rbsOwnedCollections2 ) X-NDS_NONREMOVABLE '1' " +
      "X-NDS_ACL_TEMPLATES '16#subtree#[Creator]#[Entry Rights]' )"

    expect = {
      :name => ["Top"],
      :structural => ["TRUE"],
      :must => ["objectClass"],
      :x_nds_nonremovable => ["1"],
      :x_nds_acl_templates => ['16#subtree#[Creator]#[Entry Rights]'],
    }
    assert_schema(expect, "Top", top_schema)
  end

  def test_sup_with_oid_start_with_upper_case
    organizational_person_schema =
      "( 2.5.6.7 NAME 'organizationalPerson' SUP Person STRUCTURAL MAY " +
      "( facsimileTelephoneNumber $ l $ eMailAddress $ ou $ " +
      "physicalDeliveryOfficeName $ postalAddress $ postalCode $ " +
      "postOfficeBox $ st $ street $ title $ mailboxLocation $ " +
      "mailboxID $ uid $ mail $ employeeNumber $ destinationIndicator $ " +
      "internationaliSDNNumber $ preferredDeliveryMethod $ " +
      "registeredAddress $ teletexTerminalIdentifier $ telexNumber $ " +
      "x121Address $ businessCategory $ roomNumber $ x500UniqueIdentifier " +
      ") X-NDS_NAMING ( 'cn' 'ou' 'uid' ) X-NDS_CONTAINMENT ( " +
      "'Organization' 'organizationalUnit' 'domain' ) X-NDS_NAME " +
      "'Organizational Person' X-NDS_NOT_CONTAINER '1' " +
      "X-NDS_NONREMOVABLE '1' )"

    expect = {
      :name => ["organizationalPerson"],
      :sup => ["Person"],
      :structural => ["TRUE"],
      :x_nds_naming => ["cn", "ou", "uid"],
      :x_nds_containment => ["Organization", "organizationalUnit", "domain"],
      :x_nds_name => ["Organizational Person"],
      :x_nds_not_container => ["1"],
      :x_nds_nonremovable => ["1"],
    }
    assert_schema(expect, "organizationalPerson",
                  organizational_person_schema)
  end

  priority :normal
  def test_text_oid
    text_oid_schema = "( mysite-oid NAME 'mysite' " +
                      "SUP groupofuniquenames STRUCTURAL " +
                      "MUST ( mysitelang $ mysiteurl ) " +
                      "MAY ( mysitealias $ mysitecmsurl ) " +
                      "X-ORIGIN 'user defined' )"
    expect = {
      :name => ["mysite"],
      :sup => ["groupofuniquenames"],
      :structural => ["TRUE"],
      :must => %w(mysitelang mysiteurl),
      :may => %w(mysitealias mysitecmsurl),
      :x_origin => ["user defined"]
    }
    assert_schema(expect, "mysite", text_oid_schema)

    text_oid_attribute_schema = "( mysiteurl-oid NAME 'mysiteurl' " +
                                "SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 " +
                                "SINGLE-VALUE X-ORIGIN 'user defined' )"
    expect = {
      :name => ["mysiteurl"],
      :syntax => ["1.3.6.1.4.1.1466.115.121.1.15"],
      :single_value => ["TRUE"],
      :x_origin => ["user defined"]
    }
    assert_schema(expect, "mysiteurl", text_oid_attribute_schema)
  end

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

    schema = ActiveLdap::Schema.new({"attributeTypes" => [jpeg_photo_schema],
                                     "ldapSyntaxes" => [jpeg_schema]})
    assert(schema.binary?("jpegPhoto"))
  end

  private
  def assert_schema(expect, name, schema)
    sub = "objectClass"
    entry = {sub => [schema]}
    schema = ActiveLdap::Schema.new(entry)
    actual = {}
    normalized_expect = {}
    expect.each do |key, value|
      normalized_key = key.to_s.gsub(/_/, "-")
      normalized_expect[normalized_key] = value
      actual[normalized_key] = schema[sub, name, normalized_key]
    end
    assert_equal(normalized_expect, actual)
  end
end
