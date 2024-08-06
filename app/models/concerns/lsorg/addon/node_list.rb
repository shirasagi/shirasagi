module Lsorg::Addon
  module NodeList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      embeds_ids :root_groups, class_name: "Cms::Group"
      embeds_ids :exclude_groups, class_name: "Cms::Group"

      permit_params root_group_ids: []
      permit_params exclude_group_ids: []

      validate :validate_loop_format

      self.use_loop_formats = %i(liquid)
    end

    def root_only(groups)
      names = groups.map(&:name)
      names = names.select do |name|
        parent = names.find { |n| name.start_with?("#{n}/") }
        parent.nil?
      end
      names.map { |name| groups.find { |g| g.name == name } }
    end

    def effective_root_groups
      root_only(root_groups)
    end

    def effective_exclude_groups
      root_only(exclude_groups)
    end

    private

    def validate_loop_format
      self.loop_format = "liquid"
    end
  end
end
