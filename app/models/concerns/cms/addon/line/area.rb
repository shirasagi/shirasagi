module Cms::Addon
  module Line::Area
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      attr_accessor :in_areas

      embeds_many :areas, class_name: "Cms::Line::Area", validate: false
      permit_params in_areas: [:x, :y, :width, :height, :type, :text, :data, :uri, :menu_id]
      validate :validate_in_areas
    end

    def target_options
      I18n.t("cms.options.line_richmenu_target").map { |k, v| [v, k] }
    end

    private

    def validate_in_areas
      return if in_areas.nil?

      areas = []
      in_areas.each_with_index do |item, idx|
        item = Cms::Line::Area.new(item)
        next if !(item.x && item.y && item.width && item.height)
        errors.add :base, "#{idx + 1}: #{item.errors.full_messages.join(", ")}" if !item.valid?
        areas << item
      end
      self.areas = areas if errors.empty?
    end
  end
end
