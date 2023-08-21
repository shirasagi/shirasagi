module Gws::StaffRecord::PublicYearlyFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_year
  end

  private

  def set_year
    year_id = params.dig(:s, :year_id)
    if year_id.present?
      @cur_year = Gws::StaffRecord::Year.site(@cur_site).where(id: year_id).first
    else
      @cur_year = Gws::StaffRecord::Year.site(@cur_site).first
    end

    render(html: t('gws/staff_record.errors.no_data'), layout: true) unless @cur_year
  end

  def set_search_params
    @s = OpenStruct.new params[:s]
    unless @s[:section_name]
      user = @cur_year.yearly_users.where(code: @cur_user.organization_uid).first
      @s[:section_name] = user.try(:section_name) if @cur_year.yearly_groups.where(name: user.try(:section_name)).present?
      @s[:section_name] ||= @cur_group.trailing_name if @cur_year.yearly_groups.where(name: @cur_group.trailing_name).present?
    end
  end
end
