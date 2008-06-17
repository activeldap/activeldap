require 'English'
require 'md5'
require 'sha1'

module ActiveLdap
  module UserPassword
    module_function
    def valid?(password, hashed_password)
      unless /^\{([A-Z][A-Z\d]+)\}/ =~ hashed_password
        raise ArgumentError, _("Invalid hashed password: %s") % hashed_password
      end
      type = $1
      hashed_password_without_type = $POSTMATCH
      normalized_type = type.downcase
      unless respond_to?(normalized_type)
        raise ArgumentError, _("Unknown Hash type: %s") % type
      end
      salt_extractor = "extract_salt_for_#{normalized_type}"
      if respond_to?(salt_extractor)
        salt = send(salt_extractor, hashed_password_without_type)
        if salt.nil?
          raise ArgumentError,
            _("Can't extract salt from hashed password: %s") % hashed_password
        end
        generated_password = send(normalized_type, password, salt)
      else
        generated_password = send(normalized_type, password)
      end
      hashed_password == generated_password
    end

    def crypt(password, salt=nil)
      salt ||= "$1$#{Salt.generate(8)}"
      "{CRYPT}#{password.crypt(salt)}"
    end

    def extract_salt_for_crypt(crypted_password)
      if /^\$1\$/ =~ crypted_password
        $MATCH + $POSTMATCH[0, 8].sub(/\$.*/, '') + "$"
      else
        crypted_password[0, 2]
      end
    end

    def md5(password)
      "{MD5}#{[MD5.md5(password).digest].pack('m').chomp}"
    end

    def smd5(password, salt=nil)
      if salt and salt.size != 4
        raise ArgumentError, _("salt size must be == 4: %s") % salt.inspect
      end
      salt ||= Salt.generate(4)
      md5_hash_with_salt = "#{MD5.md5(password + salt).digest}#{salt}"
      "{SMD5}#{[md5_hash_with_salt].pack('m').chomp}"
    end

    def extract_salt_for_smd5(smd5ed_password)
      Base64.decode64(smd5ed_password)[-4, 4]
    end

    def sha(password)
      "{SHA}#{[SHA1.sha1(password).digest].pack('m').chomp}"
    end

    def ssha(password, salt=nil)
      if salt and salt.size != 4
        raise ArgumentError, _("salt size must be == 4: %s") % salt.inspect
      end
      salt ||= Salt.generate(4)
      sha1_hash_with_salt = "#{SHA1.sha1(password + salt).digest}#{salt}"
      "{SSHA}#{[sha1_hash_with_salt].pack('m').chomp}"
    end

    def extract_salt_for_ssha(sshaed_password)
      extract_salt_for_smd5(sshaed_password)
    end

    module Salt
      CHARS = ['.', '/', '0'..'9', 'A'..'Z', 'a'..'z'].collect do |x|
        x.to_a
      end.flatten

      module_function
      def generate(length)
        salt = ""
        length.times {salt << CHARS[rand(CHARS.length)]}
        salt
      end
    end
  end
end
