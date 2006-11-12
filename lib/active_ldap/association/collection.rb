require 'active_ldap/association/proxy'

module ActiveLdap
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
        add_entries(*entries)
      end
      alias_method(:push, :<<)
      alias_method(:concat, :<<)

      def each(&block)
        to_ary.each(&block)
      end

      def delete(*entries)
        entries = flatten_deeper(entries).reject do |entry|
          @target.delete(entry) if entry.new_entry?
          entry.new_entry?
        end
        return if entries.empty?

        delete_entries(entries)
        entries.each do |entry|
          @target.delete(entry)
        end
      end

      def replace(others)
        load_target
        deleted_entries = @target - others
        added_entries = others - @target

        delete(deleted_entries)
        concat(added_entries)
      end

      def exists?
        load_target
        not @target.empty?
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

      def add_entries(*entries)
        result = true
        load_target

        flatten_deeper(entries).each do |entry|
          result &&= insert_entry(entry) unless @owner.new_entry?
          @target << entry
        end

        result && self
      end
    end
  end
end
