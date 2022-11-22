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
  field :daily_report_date, type: DateTime, default: Time.zone.today

  permit_params :daily_report_date

  before_validation :set_name

  validates :name, presence: true, length: { maximum: 80 }
  validates :daily_report_date, presence: true, uniqueness: { scope: [:site_id, :user_id, :form_id] }

  after_clone_files :rewrite_file_ref

  scope :and_month, ->(month) { gte(daily_report_date: month.beginning_of_month).lte(daily_report_date: month.end_of_month) }
  scope :and_date, ->(date) { where(daily_report_date: date.to_date) }
  scope :and_user, ->(user) { where(user_id: user.id) }
  # scope :and_group, ->(group) { where(group_ids: group.id) }
  scope :and_groups, ->(groups) { where(group_ids: { '$in' => groups.to_a.collect(&:id) }) }

  default_scope -> {
    order_by updated: -1
  }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?

      all.keyword_in(params[:keyword], :name, :text, 'column_values.text_index')
    end

    def enum_csv(site: nil, encoding: "Shift_JIS")
      Gws::DailyReport::ReportEnumerator.new(site, all, encoding: encoding)
    end

    def user_csv(site: nil, month: Time.zone.today.beginning_of_month, encoding: "Shift_JIS")
      Gws::DailyReport::UserReportEnumerator.new(site, month, all, encoding: encoding)
    end

    def group_csv(site: nil, group: nil, encoding: "Shift_JIS")
      Gws::DailyReport::GroupReportEnumerator.new(site, group, all, encoding: encoding)
    end

    def collect_attachments
      attachment_ids = []

      attachment_ids += all.pluck(:file_ids).flatten.compact

      all.pluck(:column_values).flatten.compact.each do |bson_doc|
        if bson_doc["_type"] == Gws::Column::Value::FileUpload.name
          attachment_ids += bson_doc["file_ids"] if bson_doc["file_ids"].present?
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
        if value.is_a?(Gws::Column::Value::FileUpload)
          attachment_ids += value.file_ids if value.file_ids.present?
        end
      end
    end

    return SS::File.none if attachment_ids.blank?

    SS::File.in(id: attachment_ids)
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
