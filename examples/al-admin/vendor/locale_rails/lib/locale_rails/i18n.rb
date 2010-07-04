=begin
  locale_rails/lib/i18n.rb - Ruby/Locale for "Ruby on Rails"

  Copyright (C) 2008,2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.

=end

module I18n
  module_function

  # Gets the supported locales.
  def supported_locales 
    ::Locale.app_language_tags
  end

  # Sets the supported locales.
  #  I18n.set_supported_locales("ja-JP", "ko-KR", ...)
  def set_supported_locales(*tags)
    ::Locale.set_app_language_tags(*tags)
  end

  # Sets the supported locales as an Array.
  #  I18n.supported_locales = ["ja-JP", "ko-KR", ...]
  def supported_locales=(tags)
    ::Locale.set_app_language_tags(*tags)
  end

  # Sets the ::Locale.
  #  I18n.locale = "ja-JP"
  def locale_with_locale_rails=(tag)
    ::Locale.clear
    tag = ::Locale::Tag::Rfc.parse(tag.to_s) if tag.kind_of? Symbol
    ::Locale.current = tag
    self.locale_without_locale_rails = ::Locale.candidates(:type => :rfc)[0].to_s
  end

  # Sets the default ::Locale.
  #  I18n.default_locale = "ja"
  def default_locale=(tag)
    tag = ::Locale::Tag::Rfc.parse(tag.to_s) if tag.kind_of? Symbol
    ::Locale.default = tag
    @@default_locale = tag
  end
  
  class << self
    alias_method_chain :locale=, :locale_rails

    # MissingTranslationData is overrided to fallback messages in candidate locales.
    def locale_rails_exception_handler(exception, locale, key, options) #:nodoc:
      ret = nil
      ::Locale.candidates(:type => :rfc).each do |loc|
        begin
          ret = backend.translate(loc, key, options)
          break
        rescue I18n::MissingTranslationData 
          ret = I18n.default_exception_handler(exception, locale, key, options)
        end
      end
      ret
    end
    I18n.exception_handler = :locale_rails_exception_handler
  end

end
