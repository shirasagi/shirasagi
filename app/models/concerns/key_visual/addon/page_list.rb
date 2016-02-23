module KeyVisual::Addon
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :link_target, type: String
      field :upper_html, type: String
      field :lower_html, type: String
      permit_params :link_target, :upper_html, :lower_html
    end

    def link_target_options
      [
        [I18n.t('key_visual.options.link_target.self'), ''],
        [I18n.t('key_visual.options.link_target.blank'), 'blank'],
      ]
    end
  end
end
