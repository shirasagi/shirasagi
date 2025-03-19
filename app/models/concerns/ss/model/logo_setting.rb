module SS::Model::LogoSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  # To support high resolution display like Retina, it needs double size for limitation
  LOGO_APPLICATION_IMAGE_WIDTH = 210 * 2
  LOGO_APPLICATION_IMAGE_HEIGHT = 49 * 2
  RESIZING = [ LOGO_APPLICATION_IMAGE_WIDTH, LOGO_APPLICATION_IMAGE_HEIGHT ].freeze

  included do
    field :logo_application_name, type: String
    field :logo_application_link, type: String, default: "mypage"
    belongs_to_file :logo_application_image, class_name: "SS::LogoFile",
      resizing: RESIZING, accepts: SS::File::IMAGE_FILE_EXTENSIONS

    permit_params :logo_application_name, :logo_application_link

    validates :logo_application_name, length: { maximum: 24 }
  end

  def logo_application_link_options
    I18n.t("ss.options.logo_application_link").map { |k, v| [v, k] }
  end

  def logo_application_url
    Rails.application.routes.url_helpers.sns_mypage_path
  end
end
