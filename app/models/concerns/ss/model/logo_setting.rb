module SS::Model::LogoSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  # To support high resolution display like Retina, it needs double size for limitation
  LOGO_APPLICATION_IMAGE_WIDTH = 210 * 2
  LOGO_APPLICATION_IMAGE_HEIGHT = 49 * 2
  RESIZING = [ LOGO_APPLICATION_IMAGE_WIDTH, LOGO_APPLICATION_IMAGE_HEIGHT ].freeze

  included do
    field :logo_application_name, type: String
    belongs_to_file :logo_application_image, class_name: "SS::LogoFile", resizing: RESIZING

    permit_params :logo_application_name

    validates :logo_application_name, length: { maximum: 24 }
  end
end
