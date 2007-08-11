module ActiveLdap
  module Association
    module HasManyUtils
      private
      def collect_targets(requested_target_key, need_requested_targets=false)
        foreign_base_key = primary_key
        return [] if foreign_base_key.nil?

        requested_targets = @owner[@options[requested_target_key], true]

        components = requested_targets.reject(&:nil?)
        unless foreign_base_key == "dn"
          components = components.collect do |value|
            [foreign_base_key, value]
          end
        end

        if components.empty?
          targets = []
        elsif foreign_base_key == "dn"
          targets = foreign_class.find(components, find_options)
        else
          options = find_options(:filter => [:or, *components])
          targets = foreign_class.find(:all, options)
        end

        if need_requested_targets
          [targets, requested_targets]
        else
          targets
        end
      end
    end
  end
end
