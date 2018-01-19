class Gws::Attendance::TimeCard
  extend SS::Translation
  include SS::Document
  include Gws::Reference::Site
  include Gws::Reference::User
  include Gws::SitePermission

  # seqid :id
  field :name, type: String
  field :year_month, type: DateTime
  embeds_many :histories, class_name: 'Gws::Attendance::History'
  embeds_many :records, class_name: 'Gws::Attendance::Record'

  attr_accessor :in_year, :in_month

  permit_params :in_year, :in_month

  before_validation :set_name_and_year_month

  class << self
    def search(params = {})
      all.search_name(params).search_keyword(params)
    end

    def search_name(params = {})
      return all if params.blank? || params[:name].blank?
      all.search_text(params[:name])
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name)
    end
  end

  def year_options
    cur_year = Time.zone.now.year

    ((cur_year - 5)..(cur_year + 5)).map do |year|
      ["#{year}年", year]
    end
  end

  def month_options
    (1..12).map do |month|
      ["#{month}月", month]
    end
  end

  private

  def set_name_and_year_month
    self.year_month = Time.zone.parse("#{in_year}/#{in_month}/01")
    month = I18n.l(self.year_month.to_date, format: :attendance_year_month)
    self.name = I18n.t('gws/attendance.formats.time_card_name', month: month)
  end
end
