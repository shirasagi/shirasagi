class Gws::DailyReport::Report
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::DailyReport::CustomForm
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  field :daily_report_date, type: DateTime

  belongs_to :daily_report_group, class_name: 'Gws::Group'

  has_many :comments, class_name: 'Gws::DailyReport::Comment', dependent: :destroy

  permit_params :daily_report_date

  before_validation :set_name
  before_validation :set_daily_report_group

  validates :name, presence: true, length: { maximum: 80 }
  validates :daily_report_date, presence: true, uniqueness: { scope: [:site_id, :user_id, :form_id] }

  after_clone_files :rewrite_file_ref

  scope :and_month, ->(month) { gte(daily_report_date: month.beginning_of_month).lte(daily_report_date: month.end_of_month) }
  scope :and_date, ->(date) { where(daily_report_date: date.to_date) }
  scope :and_user, ->(user) { where(user_id: user.id) }
  scope :and_groups, ->(groups) { where(daily_report_group_id: { '$in' => groups.to_a.collect(&:id) }) }

  default_scope -> {
    order_by updated: -1
  }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria.search_keyword(params)
    end

    def search_keyword(params)
      return all if params[:keyword].blank?

      all.keyword_in(params[:keyword], :name, :text, 'column_values.text_index')
    end

    def enum_csv(site: nil, user: nil, options: {})
      Gws::DailyReport::ReportEnumerator.new(site, user, all, options)
    end

    def user_csv(site: nil, user: nil, options: {})
      Gws::DailyReport::UserReportEnumerator.new(site, user, all, options)
    end

    def group_csv(site: nil, user: nil, options: {})
      Gws::DailyReport::GroupReportEnumerator.new(site, user, all, options)
    end

    def group_share_csv(site: nil, user: nil, options: {})
      Gws::DailyReport::GroupShareReportEnumerator.new(site, user, all, options)
    end
  end

  def readable?(user, opts)
    editable?(user, opts)
  end

  def editable?(user, opts)
    allowed?(:edit, user, opts)
  end

  def destroyable?(user, opts)
    editable?(user, opts)
  end

  def manageable?(user, opts)
    return true if allowed?(:manage_all, user, opts)
    return true if user_id == user.id

    site = opts[:site] || @cur_site || site
    date = opts[:date] || Time.zone.now

    return false unless allowed?(:manage_private, user, opts)
    return false if site.fiscal_year(date) != site.fiscal_year
    user.groups.in_group(site).distinct(:id).include?(daily_report_group_id)
  end

  def column_comments(report_key)
    case report_key
    when 'small_talk'
      Gws::DailyReport::Comment.where(report_key: report_key, report_id: id)
    else
      Gws::DailyReport::Comment.where(report_key: 'column_value_ids', report_id: id, column_id: report_key)
    end
  end

  def max_column_comments_length
    length = []
    length << column_comments('small_talk').length
    column_values.each do |column_value|
      length << column_comments(column_value.column_id).length
    end
    length.max
  end

  private

  def set_name
    self.name = begin
      date = I18n.l(daily_report_date.to_date, format: :long)
      I18n.t('gws/daily_report.formats.daily_report_full_name', user_name: user_name, date: date)
    rescue
      nil
    end
  end

  def set_daily_report_group
    form = @cur_form || self.form
    return unless form
    return unless form.daily_report_group

    self.daily_report_group_id = form.daily_report_group_id
  end

  def rewrite_file_ref
    text = self.text
    return if text.blank?

    in_clone_file.each do |old_id, new_id|
      old_file = SS::File.find(old_id) rescue nil
      new_file = SS::File.find(new_id) rescue nil
      next if old_file.blank? || new_file.blank?

      text.gsub!(old_file.url.to_s, new_file.url.to_s)
      text.gsub!(old_file.thumb_url.to_s, new_file.thumb_url.to_s) if old_file.thumb.present? && new_file.thumb.present?
    end

    self.text = text
  end
end
