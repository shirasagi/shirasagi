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

  before_validation :set_name

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

    def in_groups(groups)
      group_ids = []
      groups.each do |group|
        group_ids += Gws::Group.in_group(group).pluck(:id)
      end
      group_ids.uniq!

      users = Gws::User.in(group_ids: group_ids).active
      user_ids = users.pluck(:id)

      all.in(user_id: user_ids)
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

  def set_name
    self.name ||= begin
      month = I18n.l(self.year_month.to_date, format: :attendance_year_month)
      I18n.t('gws/attendance.formats.time_card_name', month: month)
    end
  end
end
