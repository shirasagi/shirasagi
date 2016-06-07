module Member::Addon::Photo
  module LicenseSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :license_free, type: String
      field :license_not_free, type: String

      permit_params :license_free, :license_not_free
    end
  end
end
