=begin
  lib/locale_rails/action_controller.rb - Ruby/Locale for "Ruby on Rails"

  Copyright (C) 2008-2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'action_controller/caching'

module ActionController #:nodoc:

  module Caching
    module Fragments
      @@fragmented_locales = []
      def fragment_cache_key_with_locale(name) 
        ret = fragment_cache_key_without_locale(name)
        if ret.is_a? String
          unless @@fragmented_locales.include? I18n.locale
            @@fragmented_locales << I18n.locale
          end
          ret.gsub(/:/, ".") << "_#{I18n.locale}"
        else
          ret
        end
      end
      alias_method_chain :fragment_cache_key, :locale

      def expire_fragment_with_locale(name, options = nil)
        return unless perform_caching

        fc_store = (respond_to? :cache_store) ? cache_store : fragment_cache_store
        key = name.is_a?(Regexp) ? name : fragment_cache_key_without_locale(name)
        if key.is_a?(Regexp)
          self.class.benchmark "Expired fragments matching: #{key.source}" do
            fc_store.delete_matched(key, options)
          end
        else
          key = key.gsub(/:/, ".")
          self.class.benchmark "Expired fragment: #{key}, lang = #{@@fragmented_locales}" do
            @@fragmented_locales.each do |lang|
              fc_store.delete("#{key}_#{lang}", options)
            end
          end
        end
      end
      alias_method_chain :expire_fragment, :locale
    end
  end
end
