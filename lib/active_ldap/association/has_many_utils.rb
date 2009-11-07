module ActiveLdap
  module Association
    module HasManyUtils
      private
      def collect_targets(requested_target_key, need_requested_targets=false)
        _foreign_key = foreign_key
        return [] if _foreign_key.nil?

        requested_targets = @owner[requested_target_key, true]
        requested_targets = requested_targets.reject(&:nil?)
        if requested_targets.empty?
          targets = []
        elsif _foreign_key == "dn"
          requested_targets = requested_targets.collect do |target|
            if target.is_a?(DN)
              target
            else
              DN.parse(target)
            end
          end
          targets = []
          requested_targets.each do |target|
            begin
              targets << foreign_class.find(target, find_options)
            rescue EntryNotFound
            end
          end
        else
          components = requested_targets.collect do |value|
            [_foreign_key, value]
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
