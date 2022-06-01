module Cms::Addon
  module Line::Area
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      field :in_areas, type: Array # 画像、タップ領域に変更を加えた際に、updated を更新して、APIに新規登録したい
      embeds_many :areas, class_name: "Cms::Line::Area"
      permit_params in_areas: [:x, :y, :width, :height, :type, :text, :data, :uri, :menu_id]
      validate :validate_in_areas
    end

    def target_options
      I18n.t("cms.options.line_richmenu_target").map { |k, v| [v, k] }
    end

    private

    def validate_in_areas
      self.in_areas = in_areas.to_a rescue nil
      return if in_areas.blank?

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
