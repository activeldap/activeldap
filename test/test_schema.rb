require 'al-test-utils'

class TestSchema < Test::Unit::TestCase
  priority :must
  def test_dit_content_rule
    object_class_schema = "( 2.5.6.6 NAME 'person' DESC " +
      "'RFC2256: a person' SUP top STRUCTURAL MUST sn " +
      "MAY ( userPassword $ telephoneNumber ) )"
    dit_content_rule_schema = "( 2.5.6.6 NAME 'person' MUST cn " +
      "MAY ( seeAlso $ description ) )"
    attributes_schema =
      [
       "( 2.5.4.3 NAME 'cn' SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' SINGLE-VALUE )",
       "( 2.5.4.4 NAME 'sn' SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' SINGLE-VALUE )",
       "( 2.5.4.35 NAME 'userPassword' SYNTAX '1.3.6.1.4.1.1466.115.121.1.40' )",
       "( 2.5.4.20 NAME 'telephoneNumber' SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' SINGLE-VALUE )",
       "( 2.5.4.34 NAME 'seeAlso' SYNTAX '1.3.6.1.4.1.1466.115.121.1.12' )",
       "( 2.5.4.13 NAME 'description' SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' )",
      ]

    entry = {
      "objectClasses" => [object_class_schema],
      "dITContentRules" => [dit_content_rule_schema],
      "attributeTypes" => attributes_schema,
    }

    schema = ActiveLdap::Schema.new(entry)
    object_class = schema.object_class("person")
    assert_equal({
                   :must => ["sn", "cn"],
                   :may => ["userPassword", "telephoneNumber",
                            "seeAlso", "description"],
                 },
                 {
                   :must => object_class.must.collect(&:name),
                   :may => object_class.may.collect(&:name),
                 })
  end

  priority :normal
  def test_oid_list_with_just_only_one_oid
    ou_schema = "( 2.5.6.5 NAME 'organizationalUnit' SUP top STRUCTURAL MUST " +
      "(ou ) MAY (c $ l $ st $ street $ searchGuide $ businessCategory $ " +
      "postalAddress $ postalCode $ postOfficeBox $ " +
      "physicalDeliveryOfficeName $ telephoneNumber $ telexNumber $ " +
      "teletexTerminalIdentifier $ facsimileTelephoneNumber $ x121Address $ " +
      "internationalISDNNumber $ registeredAddress $ destinationIndicator $ " +
      "preferredDeliveryMethod $ seeAlso $ userPassword $ co $ countryCode $ " +
      "desktopProfile $ defaultGroup $ managedBy $ uPNSuffixes $ gPLink $ " +
      "gPOptions $ msCOM-UserPartitionSetLink $ thumbnailLogo ) ) "

    expect = {
      :name => ["organizationalUnit"],
      :sup => ["top"],
      :structural => ["TRUE"],
      :must => %w(ou),
      :may => %w(c l st street searchGuide businessCategory
                 postalAddress postalCode postOfficeBox
                 physicalDeliveryOfficeName telephoneNumber telexNumber
                 teletexTerminalIdentifier facsimileTelephoneNumber
                 x121Address internationalISDNNumber registeredAddress
                 destinationIndicator preferredDeliveryMethod seeAlso
                 userPassword co countryCode desktopProfile defaultGroup
                 managedBy uPNSuffixes gPLink gPOptions
                 msCOM-UserPartitionSetLink thumbnailLogo),
    }
    assert_schema(expect, "2.5.6.5", ou_schema)
    assert_schema(expect, "organizationalUnit", ou_schema)
  end

  def test_normalize_attribute_value
    entry = {
      "attributeTypes" =>
      [
       "( 0.9.2342.19200300.100.1.25 NAME ( 'dc' 'domainComponent' ) DESC " +
       "'RFC1274/2247: domain component' EQUALITY caseIgnoreIA5Match SUBSTR " +
       "caseIgnoreIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 " +
       "SINGLE-VALUE )",
      ],
      "ldapSyntaxes" =>
      [
       "( 1.3.6.1.4.1.1466.109.114.1 NAME 'caseExactIA5Match' " +
       "SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )",
      ],
    }

    schema = ActiveLdap::Schema.new(entry)
    dc = schema.attribute("dc")
    assert_equal(["com"], dc.normalize_value("com"))
    assert_equal(["com"], dc.normalize_value(["com"]))
    assert_raise(ActiveLdap::AttributeValueInvalid) do
      dc.normalize_value(["com", "co.jp"])
    end
    assert_equal([{"lang-en" => ["com"]},
                  {"lang-ja" => ["co.jp"]}],
                 dc.normalize_value([{"lang-en" => "com"},
                                     {"lang-ja" => "co.jp"}]))
  end

  def test_syntax_validation
    entry = {
      "attributeTypes" =>
      [
       "( 2.5.4.34 NAME 'seeAlso' DESC 'RFC2256: DN of related object'" +
       "SUP distinguishedName )",
       "( 2.5.4.49 NAME 'distinguishedName' DESC 'RFC2256: common " +
       "supertype of DN attributes' EQUALITY distinguishedNameMatch "+
       "SYNTAX 1.3.6.1.4.1.1466.115.121.1.12 )",
      ],
      "ldapSyntaxes" =>
      [
       "( 1.3.6.1.4.1.1466.115.121.1.12 DESC 'Distinguished Name' )",
      ],
    }

    schema = ActiveLdap::Schema.new(entry)
    see_also = schema.attribute("seeAlso")
    assert(see_also.valid?("cn=test,dc=example,dc=com"))
    assert(!see_also.valid?("test"))
  end

  def test_super_class?
    group = 'objectClasses'
    entry = {
      group => [
                "( 2.5.6.6 NAME 'person' DESC 'RFC2256: a person' SUP " +
                "top STRUCTURAL MUST ( sn $ cn ) MAY ( userPassword $ " +
                "telephoneNumber $ seeAlso $ description ) )",

                "( 2.5.6.7 NAME 'organizationalPerson' DESC 'RFC2256: " +
                "an organizational person' SUP person STRUCTURAL MAY ( " +
                "title $ x121Address $ registeredAddress $ " +
                "destinationIndicator $ preferredDeliveryMethod $ " +
                "telexNumber $ teletexTerminalIdentifier $ telephoneNumber " +
                "$ internationaliSDNNumber $ facsimileTelephoneNumber $ " +
                "street $ postOfficeBox $ postalCode $ postalAddress $ " +
                "physicalDeliveryOfficeName $ ou $ st $ l ) )",

                "( 2.16.840.1.113730.3.2.2 NAME 'inetOrgPerson' DESC " +
                "'RFC2798: Internet Organizational Person' SUP " +
                "organizationalPerson STRUCTURAL MAY ( audio $ " +
                "businessCategory $ carLicense $ departmentNumber $ " +
                "displayName $ employeeNumber $ employeeType $ givenName " +
                "$ homePhone $ homePostalAddress $ initials $ jpegPhoto " +
                "$ labeledURI $ mail $ manager $ mobile $ o $ pager $ " +
                "photo $ roomNumber $ secretary $ uid $ userCertificate $ " +
                "x500UniqueIdentifier $ preferredLanguage $ " +
                "userSMIMECertificate $ userPKCS12 ) )",
               ]
    }
    schema = ActiveLdap::Schema.new(entry)

    person = schema.object_class('person')
    organizational_person = schema.object_class("organizationalPerson")
    inet_org_person = schema.object_class("inetOrgPerson")

    assert_equal([false, false, false],
                 [person.super_class?(person),
                   person.super_class?(organizational_person),
                   person.super_class?(inet_org_person)])

    assert_equal([true, false, false],
                 [organizational_person.super_class?(person),
                  organizational_person.super_class?(organizational_person),
                  organizational_person.super_class?(inet_org_person)])

    assert_equal([true, true, false],
                 [inet_org_person.super_class?(person),
                  inet_org_person.super_class?(organizational_person),
                  inet_org_person.super_class?(inet_org_person)])
  end

  def test_duplicate_schema
    sasNMASProductOptions_schema =
      "( 2.16.840.1.113719.1.39.42.1.0.38 NAME 'sasNMASProductOptions' " +
      "SYNTAX 1.3.6.1.4.1.1466.115.121.1.40{64512} SINGLE-VALUE " +
      "X-NDS_PUBLIC_READ '1' )"
    rADIUSActiveConnections_schema =
      "( 2.16.840.1.113719.1.39.42.1.0.38 NAME 'rADIUSActiveConnections' " +
      "SYNTAX 1.3.6.1.4.1.1466.115.121.1.40{64512} X-NDS_NAME " +
      "'RADIUS:ActiveConnections' X-NDS_NOT_SCHED_SYNC_IMMEDIATE '1' )"

    sasNMASProductOptions = 'sasNMASProductOptions'
    rADIUSActiveConnections = 'rADIUSActiveConnections'
    sasNMASProductOptions_aliases =
      [sasNMASProductOptions, []]
    rADIUSActiveConnections_aliases =
      [rADIUSActiveConnections, []]
    sas_radius_aliases = [sasNMASProductOptions, [rADIUSActiveConnections]]
    radius_sas_aliases = [rADIUSActiveConnections, [sasNMASProductOptions]]

    assert_attribute_aliases([sasNMASProductOptions_aliases],
                             [sasNMASProductOptions],
                             [sasNMASProductOptions_schema],
                             false)
    assert_attribute_aliases([rADIUSActiveConnections_aliases],
                             [rADIUSActiveConnections],
                             [rADIUSActiveConnections_schema],
                             false)

    assert_attribute_aliases([sasNMASProductOptions_aliases,
                              sas_radius_aliases],
                             [sasNMASProductOptions,
                              rADIUSActiveConnections],
                             [sasNMASProductOptions_schema,
                              rADIUSActiveConnections_schema],
                             false)
    assert_attribute_aliases([rADIUSActiveConnections_aliases,
                              radius_sas_aliases],
                             [rADIUSActiveConnections,
                              sasNMASProductOptions],
                             [rADIUSActiveConnections_schema,
                              sasNMASProductOptions_schema],
                             false)

    assert_attribute_aliases([sas_radius_aliases,
                              sas_radius_aliases],
                             [rADIUSActiveConnections,
                              sasNMASProductOptions],
                             [sasNMASProductOptions_schema,
                              rADIUSActiveConnections_schema],
                             false)
    assert_attribute_aliases([radius_sas_aliases,
                              radius_sas_aliases],
                             [sasNMASProductOptions,
                              rADIUSActiveConnections],
                             [rADIUSActiveConnections_schema,
                              sasNMASProductOptions_schema],
                             false)

    assert_attribute_aliases([sas_radius_aliases,
                              sas_radius_aliases],
                             [sasNMASProductOptions,
                              rADIUSActiveConnections],
                             [sasNMASProductOptions_schema,
                              rADIUSActiveConnections_schema],
                             true)
    assert_attribute_aliases([radius_sas_aliases,
                              radius_sas_aliases],
                             [rADIUSActiveConnections,
                              sasNMASProductOptions],
                             [rADIUSActiveConnections_schema,
                              sasNMASProductOptions_schema],
                             true)
  end

  def test_empty_schema
    assert_make_schema_with_empty_entries(nil)
    assert_make_schema_with_empty_entries({})
    assert_make_schema_with_empty_entries({"someValues" => ["aValue"]})
  end

  def test_empty_schema_value
    schema = ActiveLdap::Schema.new({"attributeTypes" => nil})
    assert_equal([], schema["attributeTypes", "cn", "DESC"])
  end

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
    assert(schema.attribute("jpegPhoto").binary?)
  end

  private
  def assert_schema(expect, name, schema)
    sub = "objectClasses"
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
    schema
  end

  def assert_make_schema_with_empty_entries(entries)
    schema = ActiveLdap::Schema.new(entries)
    assert_equal([], schema["attributeTypes", "cn", "DESC"])
    assert_equal([], schema["ldapSyntaxes",
                            "1.3.6.1.4.1.1466.115.121.1.5",
                            "DESC"])
    assert_equal([], schema["objectClasses", "posixAccount", "MUST"])
  end

  def assert_attribute_aliases(expected, keys, schemata, ensure_parse)
    group = 'attributeTypes'
    entry = {group => schemata}
    schema = ActiveLdap::Schema.new(entry)
    schema.send(:ensure_parse, group) if ensure_parse
    result = keys.collect do |key|
      attribute = schema.attribute(key)
      [attribute.name, attribute.aliases]
    end
    assert_equal(expected, result)
  end
end
