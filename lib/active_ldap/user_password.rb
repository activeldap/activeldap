require 'base64'
require 'md5'
require 'sha1'

module ActiveLdap
  module UserPassword
    module_function
    def crypt(password, salt=nil)
      salt ||= "$1$#{make_salt(8)}"
      "{CRYPT}#{password.crypt(salt)}"
    end

    def md5(password)
      "{MD5}#{Base64.encode64(MD5.md5(password).digest).chomp}"
    end

    def smd5(password, salt=nil)
      if salt and salt.size != 4
        raise ArgumentError.new("salt size must be == 4")
      end
      salt ||= make_salt(4)
      md5_hash_with_salt = "#{MD5.md5(password + salt).digest}#{salt}"
      "{SMD5}#{Base64.encode64(md5_hash_with_salt).chomp}"
    end

    def sha(password)
      "{SHA}#{Base64.encode64(SHA1.sha1(password).digest).chomp}"
    end

    def ssha(password, salt=nil)
      if salt and salt.size != 4
        raise ArgumentError.new("salt size must be == 4")
      end
      salt ||= make_salt(4)
      sha1_hash_with_salt = "#{SHA1.sha1(password + salt).digest}#{salt}"
      "{SSHA}#{Base64.encode64(sha1_hash_with_salt).chomp}"
    end

    SALT_CHARS = ['.', '/', '0'..'9', 'A'..'Z', 'a'..'z'].collect do |x|
      x.to_a
    end.flatten

    def make_salt(length)
      salt = ""
      length.times {salt << SALT_CHARS[rand(SALT_CHARS.length)]}
      salt
    end
  end
end
