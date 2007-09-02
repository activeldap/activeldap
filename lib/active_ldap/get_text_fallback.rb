module ActiveLdap
  module GetTextFallback
    class << self
      def included(base)
        base.extend(self)
      end
    end

    module_function
    def bindtextdomain(domain_name, *args)
    end

    def gettext(msg_id)
      msg_id
    end

    def ngettext(arg1, arg2, arg3=nil)
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

    def sgettext(msg_id, div='|')
      index = msg_id.rindex(div)
      if index
        msg_id[(index + 1)..-1]
      else
        msg_id
      end
    end

    alias_method(:_, :gettext)
    alias_method(:n_, :ngettext)
    alias_method(:s_, :sgettext)
  end

  GetText = GetTextFallback
end
