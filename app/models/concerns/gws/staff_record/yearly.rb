module Gws::StaffRecord::Yearly
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :year, type: Integer
    field :year_name, type: String

    permit_params :year

    validates :year, presence: true
    validates :year_name, presence: true

    before_validation :set_year_name, if: -> { year.present? }
  end

  def year_options
    Gws::StaffRecord::Year.site(@cur_site || site).
      map { |c| [c.name_with_year, c.year] }
  end

  private

  def set_year_name
    item = Gws::StaffRecord::Year.where(site_id: site_id, year: year).first
    self.year_name = item ? item.name : nil
  end
end
