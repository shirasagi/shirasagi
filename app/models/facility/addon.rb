# coding: utf-8
module Facility::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      field :address, type: String
      field :tel, type: String
      field :fax, type: String
      field :homepage, type: String
      field :hours, type: String
      field :holiday, type: String

      field :kana, type: String
      field :principal, type: String
      field :extended_day_care, type: String

      permit_params :address, :tel, :fax, :homepage, :hours, :holiday
      permit_params :kana, :principal, :extended_day_care
    end
  end

end
