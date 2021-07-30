module KeyVisual::Addon::SwiperSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :link_target, type: String
    field :kv_speed, type: Integer
    field :kv_pause, type: Integer

    permit_params :link_target, :kv_speed, :kv_pause
  end

  def link_target_options
    [
      [I18n.t('key_visual.options.link_target.self'), ''],
      [I18n.t('key_visual.options.link_target.blank'), 'blank'],
    ]
  end
end
