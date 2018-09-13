module Gws::StaffRecord::PublicYearlyFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_year
  end

  private

  def set_year
    year_id = params.dig(:s, :year_id)
    @cur_year = Gws::StaffRecord::Year.site(@cur_site).where(id: year_id).first if year_id
    @cur_year ||= Gws::StaffRecord::Year.site(@cur_site).first

    render(html: t('gws/staff_record.errors.no_data'), layout: true) unless @cur_year
  end
end
