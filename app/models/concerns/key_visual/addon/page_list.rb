module KeyVisual::Addon::PageList
  extend ActiveSupport::Concern
  extend SS::Addon

  AVAILABLE_LINK_TARGETS = %w(_blank).freeze

  included do
    field :link_target, type: String
    field :upper_html, type: String
    field :lower_html, type: String
    field :kv_speed, type: Integer
    field :kv_pause, type: Integer
    permit_params :link_target, :upper_html, :lower_html, :kv_speed, :kv_pause
    validates :link_target, inclusion: { in: AVAILABLE_LINK_TARGETS, allow_blank: true }
  end

  def link_target_options
    AVAILABLE_LINK_TARGETS.map { [ I18n.t(_1, scope: "ss.options.link_target"), _1 ] }
  end
end
