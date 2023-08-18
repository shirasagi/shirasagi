module Member::Addon::Photo
  module License
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :license_name, type: String
      permit_params :license_name

      validates :license_name, presence: true
    end

    def license_name_options
      [
        [I18n.t('member.options.license_name.free'), 'free'],
        [I18n.t('member.options.license_name.not_free'), 'not_free'],
      ]
    end

    def t_license_name(key = nil)
      key ||= license_name
      license_name_options.to_h.invert[key.to_s]
    end
  end
end
