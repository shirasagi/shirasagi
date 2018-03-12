class Opendata::DatasetDownloadReport
  include ActiveModel::Model

  attr_accessor :period,
                :start_year,
                :start_month,
                :end_year,
                :end_month,
                :type,
                :cur_node,
                :cur_site,
                :cur_user

  validate :start_is_new_date_than_end

  def initialize(attributes={})
    super
    today = Time.zone.now
    @start_year ||= today.year
    @start_month ||= today.month
    @end_year ||= today.year
    @end_month ||= today.month
  end

  def years
    sy = Time.zone.today.year - 10
    ey = Time.zone.today.year
    (sy..ey).to_a.reverse.map { |d| ["#{d}#{I18n.t('datetime.prompts.year')}", d] }
  end

  def months
    (1..12).to_a.map { |d| ["#{d}#{I18n.t('datetime.prompts.month')}", d] }
  end

  def types
    [:day, :month, :year].map { |t| [self.class.human_attribute_name("type.#{t}"), t] }
  end

  def start_date
    Time.zone.local(start_year, start_month)
  end

  def end_date
    Time.zone.local(end_year, end_month).end_of_month
  end

  def csv
    Opendata::DatasetDownloadReport::Aggregate.generate_csv(self)
  end

  private

  def start_is_new_date_than_end
    if start_date > end_date
      errors.add :base, :period
    end
  end
end
