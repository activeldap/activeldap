require 'al-test-utils'

class UserPasswordTest < Test::Unit::TestCase
  def test_crypt
    salt = ".WoUoU9f3IlUx9Hh7D/8y.xA6ziklGib"
    assert_equal("{CRYPT}.W57FZhV52w0s",
                 ActiveLdap::UserPassword.crypt("password", salt))

    password = "PASSWORD"
    hashed_password = ActiveLdap::UserPassword.crypt(password)
    salt = hashed_password.sub(/^\{CRYPT\}/, '')
    assert_equal(hashed_password,
                 ActiveLdap::UserPassword.crypt(password, salt))
  end

  def test_md5
    assert_equal("{MD5}X03MO1qnZdYdgyfeuILPmQ==",
                 ActiveLdap::UserPassword.md5("password"))
  end

  def test_smd5
    assert_equal("{SMD5}gjz+SUSfZaux99Xsji/No200cGI=",
                 ActiveLdap::UserPassword.smd5("password", "m4pb"))

    password = "PASSWORD"
    hashed_password = ActiveLdap::UserPassword.smd5(password)
    salt = Base64.decode64(hashed_password.sub(/^\{SMD5\}/, ''))[-4, 4]
    assert_equal(hashed_password,
                 ActiveLdap::UserPassword.smd5(password, salt))
  end

  def test_sha
    assert_equal("{SHA}W6ph5Mm5Pz8GgiULbPgzG37mj9g=",
                 ActiveLdap::UserPassword.sha("password"))
  end

  def test_ssha
    assert_equal("{SSHA}ipnlCLA1HaK3mm3hyneJIp+Px2h1RGk3",
                 ActiveLdap::UserPassword.ssha("password", "uDi7"))

    password = "PASSWORD"
    hashed_password = ActiveLdap::UserPassword.ssha(password)
    salt = Base64.decode64(hashed_password.sub(/^\{SSHA\}/, ''))[-4, 4]
    assert_equal(hashed_password,
                 ActiveLdap::UserPassword.ssha(password, salt))
  end
end
