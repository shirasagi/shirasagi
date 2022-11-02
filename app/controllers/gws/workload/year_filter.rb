module Gws::Workload::YearFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_year
    helper_method :dropdowns
  end

  private

  def set_year
    if params[:year].match?(/\A\d+\z/)
      @cur_year = @cur_site.fiscal_year
      @year = params[:year].to_i
      @year_name ||= "#{@year}#{I18n.t("ss.fiscal_year")}"
      @years ||= ((@cur_year - 10)..(@cur_year + 1)).map { |i| { _id: i, name: "#{i}#{I18n.t("ss.fiscal_year")}", trailing_name: i.to_s } }.reverse
    else
      redirect_to({ year: @cur_site.fiscal_year })
    end
  end

  def dropdowns
    %w(year)
  end
end
