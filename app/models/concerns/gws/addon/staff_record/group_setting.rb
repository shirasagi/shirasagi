module Gws::Addon::StaffRecord::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :staff_records_limit, type: Integer, default: 50
    field :divide_duties_limit, type: Integer, default: 50

    permit_params :staff_records_limit, :divide_duties_limit

    validates :staff_records_limit, numericality: { greater_than: 0 }
    validates :divide_duties_limit, numericality: { greater_than: 0 }
  end

  def staff_records_limit_options
    [10, 20, 30, 50, 100]
  end

  def divide_duties_limit_options
    [10, 20, 30, 50, 100]
  end
end
