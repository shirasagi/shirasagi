module Gws::Addon::User::PublicDuty
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :charge_name, type: String
    field :charge_address, type: String
    field :charge_tel, type: String
    field :divide_duties, type: String
    permit_params :charge_name, :charge_address, :charge_tel, :divide_duties
  end
end
