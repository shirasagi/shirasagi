module Gws::Workload::YearFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_year
  end

  private

  def set_year
    @year ||= params[:year].match?(/\A\d+\z/) ? params[:year].to_i : nil
    @year_name ||= "#{@year}年度"

    year = Time.zone.now.year
    @years ||= (year-10..year).map { |i| { _id: i, name: i.to_s, trailing_name: i.to_s } }.reverse
  end
end
