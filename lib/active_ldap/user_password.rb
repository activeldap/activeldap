require 'English'
require 'base64'
require 'digest/md5'
require 'digest/sha1'

module ActiveLdap
  module UserPassword
    module_function
    def valid?(password, hashed_password)
      unless /^\{([A-Z][A-Z\d]+)\}/ =~ hashed_password
        # Plain text password
        return hashed_password == password
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
      "{MD5}#{[Digest::MD5.digest(password)].pack('m').chomp}"
    end

    def smd5(password, salt=nil)
      if salt and salt.size < 4
        raise ArgumentError, _("salt size must be >= 4: %s") % salt.inspect
      end
      salt ||= Salt.generate(4)
      md5_hash_with_salt = "#{Digest::MD5.digest(password + salt)}#{salt}"
      "{SMD5}#{[md5_hash_with_salt].pack('m').chomp}"
    end

    def extract_salt_for_smd5(smd5ed_password)
      extract_salt_at_pos(smd5ed_password, 16)
    end

    def sha(password)
      "{SHA}#{[Digest::SHA1.digest(password)].pack('m').chomp}"
    end

    def ssha(password, salt=nil)
      if salt and salt.size < 4
        raise ArgumentError, _("salt size must be >= 4: %s") % salt.inspect
      end
      salt ||= Salt.generate(4)
      sha1_hash_with_salt = "#{Digest::SHA1.digest(password + salt)}#{salt}"
      "{SSHA}#{[sha1_hash_with_salt].pack('m').chomp}"
    end

    def extract_salt_for_ssha(sshaed_password)
      extract_salt_at_pos(sshaed_password, 20)
    end

    def extract_salt_at_pos(hashed_password, position)
      salt = Base64.decode64(hashed_password)[position..-1]
      salt == '' ? nil : salt
    end

    module Salt
      CHARS = ['.', '/'] + ['0'..'9', 'A'..'Z', 'a'..'z'].collect do |x|
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
