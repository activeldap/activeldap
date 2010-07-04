=begin
  locale_rails/lib/action_view.rb - Ruby/Locale for "Ruby on Rails"

  Copyright (C) 2008-2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.

  Original: Ruby-GetText-Package-1.92.0

=end

require 'action_view'

module ActionView #:nodoc:
   class PathSet < Array
     def _find_template_internal(file_name, format, html_fallback = false)
       begin
         return find_template_without_locale_rails(file_name, format, html_fallback)
       rescue MissingTemplate => e
       end
       nil
     end

     def find_template_with_locale_rails(original_template_path, format = nil, html_fallback = true)
      return original_template_path if original_template_path.respond_to?(:render)

      path = original_template_path.sub(/^\//, '')
      if m = path.match(/(.*)\.(\w+)$/)
        template_file_name, template_file_extension = m[1], m[2]
      else
        template_file_name = path
      end
 
      default = Locale.default.to_common
      Locale.candidates.each do |v|
        file_name = "#{template_file_name}_#{v}"
        file_name += ".#{template_file_extension}" if template_file_extension
        ret = _find_template_internal(file_name, format)
        return ret if ret
        if v == default
          # When the user locale is the default locale, find no locale file such as index.html.erb.
          ret = _find_template_internal(path, format)
        end
        return ret if ret
      end
      find_template_without_locale_rails(original_template_path, format, html_fallback)
    end
    alias_method_chain :find_template, :locale_rails

  end
end

