module SS::Addon::FacebookSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :facebook_app_id, type: String
    field :facebook_page_url, type: String

    field :opengraph_type, type: String
    validates :opengraph_type, inclusion: { in: %w(none article), allow_blank: true }
    permit_params :facebook_app_id, :facebook_page_url
    permit_params :opengraph_type
  end

  def opengraph_type_options
    %w(none article).map do |v|
      [I18n.t("views.options.opengraph_type.#{v}"), v]
    end
  end

  def opengraph_enabled?
    opengraph_type.present? && opengraph_type != 'none'
  end
end
