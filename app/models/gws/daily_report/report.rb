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

  cattr_reader(:approver_user_class) { Gws::User }

  seqid :id
  field :name, type: String
  field :daily_report_date, type: DateTime

  belongs_to :daily_report_group, class_name: 'Gws::Group'

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

    def enum_csv(site: nil, encoding: "Shift_JIS")
      Gws::DailyReport::ReportEnumerator.new(site, user, all, encoding: encoding)
    end

    def user_csv(site: nil, user: nil, group: nil, month: Time.zone.today.beginning_of_month, encoding: "Shift_JIS")
      Gws::DailyReport::UserReportEnumerator.new(site, user, group, month, all, encoding: encoding)
    end

    def group_csv(site: nil, user: nil, group: nil, encoding: "Shift_JIS")
      Gws::DailyReport::GroupReportEnumerator.new(site, user, group, all, encoding: encoding)
    end

    def collect_attachments
      attachment_ids = []

      attachment_ids += all.pluck(:file_ids).flatten.compact

      all.pluck(:column_values).flatten.compact.each do |bson_doc|
        if bson_doc["_type"] == Gws::Column::Value::FileUpload.name && bson_doc["file_ids"].present?
          attachment_ids += bson_doc["file_ids"]
        end
      end

      return SS::File.none if attachment_ids.blank?

      SS::File.in(id: attachment_ids)
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

  def enum_csv(encoding: "Shift_JIS")
    Gws::DailyReport::ReportEnumerator.new(@cur_site || site, [ self ], encoding: encoding)
  end

  def collect_attachments
    attachment_ids = []

    attachment_ids += file_ids if file_ids.present?

    if column_values.present?
      column_values.each do |value|
        if value.is_a?(Gws::Column::Value::FileUpload) && value.file_ids.present?
          attachment_ids += value.file_ids
        end
      end
    end

    return SS::File.none if attachment_ids.blank?

    SS::File.in(id: attachment_ids)
  end

  def shared_limited_access
    str = []
    reports = self.class.and_date(daily_report_date).
      where(form_id: form_id, share_limited_access: 'true').
      ne(user_id: (@cur_user || user).id)
    reports.each do |report|
      str << "#{report.limited_access}(#{report.user.try(:name)})"
    end
    str.join("\n")
  end

  def shared_small_talk
    str = []
    reports = self.class.and_date(daily_report_date).
      where(form_id: form_id, share_small_talk: 'true').
      ne(user_id: (@cur_user || user).id)
    reports.each do |report|
      str << "#{report.small_talk}(#{report.user.try(:name)})"
    end
    str.join("\n")
  end

  def shared_column_value(column_value)
    str = []
    reports = self.class.and_date(daily_report_date).
      in(share_column_ids: column_value.column_id.to_s).
      where(form_id: form_id).
      ne(user_id: (@cur_user || user).id)
    reports.each do |report|
      str << "#{column_value.value}(#{report.user.try(:name)})"
    end
    str.join("\n")
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
