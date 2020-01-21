module Gws::Addon::System::LogoSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :logo_application_name, type: String
    # To support high resolution display like Retina, it needs double size for limitation
    belongs_to_file2 :logo_application_image, class_name: "SS::LogoFile", resizing: [ 180 * 2, 32 * 2 ]

    permit_params :logo_application_name

    validates :logo_application_name, length: { maximum: 12 }
  end
end
