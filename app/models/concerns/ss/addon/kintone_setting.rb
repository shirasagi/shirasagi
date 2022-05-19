module SS::Addon
  module KintoneSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kintone_domain, type: String
      field :kintone_user, type: String
      field :kintone_password, type: String
      attr_accessor :in_kintone_password

      permit_params :kintone_domain, :kintone_user, :in_kintone_password

      before_validation :encrypt_password, if: -> { in_kintone_password.present? }
    end

    def encrypt_password
      self.kintone_password = SS::Crypt.encrypt(in_kintone_password)
    end
  end
end
