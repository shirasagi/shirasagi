module Gws::StaffRecord::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

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

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::StaffRecord::Year.allowed?(action, user, opts)
      return true if Gws::StaffRecord::Group.allowed?(action, user, opts)
      return true if Gws::StaffRecord::User.allowed?(action, user, opts)
      # super
      false
    end
  end
end
