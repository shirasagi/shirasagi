class Gws::Affair2::TimeCardForms::LeaveRecords
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :site, :user, :date, :records

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end
end
