module SS::Addon::CheckLinksSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :check_links_email, type: String
    field :check_links_message_format, type: String, default: "text"

    permit_params :check_links_email, :check_links_message_format

    validates :check_links_email, email: true, allow_blank: true
  end

  def check_links_message_format_options
    I18n.t("cms/check_links.options.message_format").map { |k, v| [v, k] }
  end

  def check_links_default_sender_address
    "shirasagi@" + domain.sub(/:.*/, "")
  end
end
