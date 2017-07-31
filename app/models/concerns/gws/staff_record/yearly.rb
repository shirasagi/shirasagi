module Gws::StaffRecord::Yearly
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :year_code, type: String
    field :year_name, type: String

    belongs_to :year, class_name: 'Gws::StaffRecord::Year'

    permit_params :year_id

    validates :year_id, presence: true
    validates :year_code, presence: true
    validates :year_name, presence: true

    before_validation :set_year_name, if: -> { year_id.present? && year_id_changed? }
  end

  def year_options
    Gws::StaffRecord::Year.site(@cur_site || site).
      map { |c| [c.name_with_code, c.id] }
  end

  private

  def set_year_name
    item = Gws::StaffRecord::Year.where(site_id: site_id, id: year_id).first
    self.year_code = item ? item.code : nil
    self.year_name = item ? item.name : nil
  end
end
