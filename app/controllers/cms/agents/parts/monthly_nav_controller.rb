class Cms::Agents::Parts::MonthlyNavController < ApplicationController
  include Cms::PartFilter::View

  before_action :set_condition_hash

  def index
    @months = []
    @cur_part.periods.times do |i|
      @months.push [ previous_month_beginning(i), contents_size(i)]
    end

    render formats: :html
  end

  private

  def set_condition_hash
    parent = @cur_part.parent
    return unless parent

    if parent.route == "cms/archive"
      @condition_hash = parent.try(:parent).try(:condition_hash)
    else
      @condition_hash = parent.try(:condition_hash)
    end
  end

  def previous_month_beginning(num)
    (Time.zone.today - num.month).beginning_of_month
  end

  def previous_month_end(num)
    (Time.zone.today - num.month).end_of_month.end_of_day
  end

  def contents_size(num)
    criteria = Cms::Page.site(@cur_site)
    criteria = criteria.and_public(@cur_date)
    criteria = criteria.where(@condition_hash) if @condition_hash.present?
    criteria = criteria.where(:released.gte => previous_month_beginning(num), :released.lte => previous_month_end(num))
    criteria.count
  end
end
