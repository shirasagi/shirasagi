module Cms::Addon::Column::Layout
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :layout, type: String
    permit_params :layout
    validate :validate_layout
  end

  private

  def validate_layout
    return if layout.blank?

    Liquid::Template.parse(layout, error_mode: :strict)
  rescue Liquid::Error => e
    self.errors.add :layout, :malformed_liquid_template, error: e.to_s
  end
end
