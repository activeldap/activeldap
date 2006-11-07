require 'activeldap/association/proxy'

module ActiveLDAP
  module Association
    class Collection < Proxy
      include Enumerable

      def to_ary
        load_target
        @target.to_ary
      end

      def reset
        @target = []
        @loaded = false
      end

      def <<(*entries)
        result = true
        load_target

        flatten_deeper(entries).each do |entry|
          result &&= insert_entry(entry) unless @owner.new_entry?
          @target << entry
        end

        result && self
      end

      alias_method(:push, :<<)
      alias_method(:concat, :<<)

      def each(&block)
        to_ary.each(&block)
      end

      private
      def flatten_deeper(array)
        array.collect do |element|
          element.respond_to?(:flatten) ? element.flatten : element
        end.flatten
      end

      def insert_entry(entry)
        entry[@options[:foreign_key_name]] = @owner[@options[:local_key_name]]
        entry.save
      end

      def load_target
        foreign_key_name = @options[:foreign_key_name]
        filter = @owner[@options[:local_key_name], false].collect do |value|
          key = val = nil
          if foreign_key_name == "dn"
            key, val = value.split(",")[0].split("=") unless value.empty?
          else
            key, val = foreign_key_name, value
          end
          [key, val]
        end.reject do |key, val|
          key.nil? or val.nil?
        end.collect do |key, val|
          "(#{key}=#{val})"
        end.join
        klass = @owner.class.has_many_association(@options[:association_id])
        klass = @owner.class.module_eval("#{klass}") if klass.is_a?(String)
        @target = klass.find(:all, :filter => "(|#{filter})")
      end
    end
  end
end
