module Gws::Affair::CapitalYearly
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :year_code, type: String
    field :year_name, type: String
    belongs_to :year, class_name: 'Gws::Affair::CapitalYear'

    permit_params :year_id

    validates :year_id, presence: true
    validates :year_code, presence: true
    validates :year_name, presence: true

    before_validation :set_year_name
  end

  private

  def set_year_name
    return unless year
    self.year_code = year.code
    self.year_name = year.name
  end
end
