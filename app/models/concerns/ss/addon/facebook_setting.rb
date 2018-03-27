module SS::Addon::FacebookSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :facebook_app_id, type: String
    field :facebook_page_url, type: String
    field :opengraph_type, type: String
    field :opengraph_defaul_image_url, type: String
    field :facebook_access_token, type: String
    field :facebook_max_text_length, type: Integer, default: 250
    field :facebook_appends_here_state, type: String
    field :facebook_appends_here_prefix, type: String
    validates :opengraph_type, inclusion: { in: %w(none article), allow_blank: true }
    validates :facebook_max_text_length,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 250 }
    permit_params :facebook_app_id, :facebook_page_url
    permit_params :opengraph_type, :opengraph_defaul_image_url
    permit_params :facebook_access_token, :facebook_max_text_length
    permit_params :facebook_appends_here_state, :facebook_appends_here_prefix
  end

  def opengraph_type_options
    %w(none article).map do |v|
      [I18n.t("ss.options.opengraph_type.#{v}"), v]
    end
  end

  def opengraph_enabled?
    opengraph_type.present? && opengraph_type != 'none'
  end

  def facebook_token_enabled?
    facebook_access_token.present?
  end

  def facebook_max_text_length_options
    [ 0, 50, 100, 150, 200, 250 ].map do |v|
      [ I18n.t("ss.options.facebook_max_text_length.#{v}"), v ]
    end
  end

  def facebook_appends_here_state_options
    %w(hide show).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def facebook_appends_here_prefix_default
    I18n.t('ss.default_here_label')
  end
end
