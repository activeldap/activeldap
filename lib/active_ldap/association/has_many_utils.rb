module ActiveLdap
  module Association
    module HasManyUtils
      private
      def collect_targets(requested_target_key, need_requested_targets=false)
        foreign_base_key = primary_key
        return [] if foreign_base_key.nil?

        requested_targets = @owner[@options[requested_target_key], true]

        requested_targets = requested_targets.reject(&:nil?)
        if requested_targets.empty?
          targets = []
        elsif foreign_base_key == "dn"
          requested_targets = requested_targets.collect do |target|
            if target.is_a?(DN)
              target.to_s
            else
              target
            end
          end
          targets = foreign_class.find(requested_targets, find_options)
        else
          components = requested_targets.collect do |value|
            [foreign_base_key, value]
          end
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
