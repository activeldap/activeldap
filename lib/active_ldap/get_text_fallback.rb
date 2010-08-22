module ActiveLdap
  module GetTextFallback
    module_function
    def add_text_domain(name, options)
    end

    module_function
    def default_available_locales=(name)
    end

    module_function
    def default_text_domain=(name)
    end

    module Translation
      class << self
        def included(base)
          base.extend(self)
        end
      end

      def _(msg_id)
        msg_id
      end

      def n_(arg1, arg2, arg3=nil)
        if arg1.kind_of?(Array)
          msg_id = arg1[0]
          msg_id_plural = arg1[1]
          n = arg2
        else
          msg_id = arg1
          msg_id_plural = arg2
          n = arg3
        end
        n == 1 ? msg_id : msg_id_plural
      end

      def N_(msg_id)
        msg_id
      end

      def Nn_(msg_id, msg_id_plural)
        [msg_id, msg_id_plural]
      end

      def s_(msg_id, div='|')
        index = msg_id.rindex(div)
        if index
          msg_id[(index + 1)..-1]
        else
          msg_id
        end
      end
    end

  end

  GetText = GetTextFallback
end
