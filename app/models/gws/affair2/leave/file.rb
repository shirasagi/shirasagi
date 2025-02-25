class Gws::Affair2::Leave::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair2::Approver
  include Gws::Addon::File
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  #permission_include_sub_groups

  attr_accessor :in_start_date, :in_start_hour, :in_start_minute
  attr_accessor :in_close_date, :in_close_hour, :in_close_minute

  seqid :id
  field :name, type: String
  field :long_name, type: String
  field :leave_type, type: String
  field :remark, type: String
  field :start_at, type: DateTime
  field :close_at, type: DateTime
  field :allday, type: String, default: "allday"
  belongs_to :special_leave, class_name: "Gws::Affair2::SpecialLeave"

  has_many :records, as: :file, class_name: "Gws::Affair2::Leave::Record",
    inverse_of: :file, dependent: :destroy

  permit_params :name, :leave_type, :remark, :allday, :special_leave_id,
    :in_start_date, :in_start_hour, :in_start_minute,
    :in_close_date, :in_close_hour, :in_close_minute

  validates :name, presence: true, length: { maximum: 80 }
  validates :leave_type, presence: true
  validate :set_start_close
  validate :validate_records

  before_save :set_long_name
  after_save :save_records

  def private_show_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair2_leave_file_path(site: site, id: id)
  end

  def workflow_wizard_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair2_leave_wizard_path(site: site.id, id: id)
  end

  def workflow_pages_path
    private_show_path
  end

  def hour_options
    (0..23).map { |h| [ I18n.t("gws/attendance.hour", count: h), h ] }
  end

  def minute_options
    0.step(45, 15).map { |m| [ I18n.t('gws/attendance.minute', count: m), m ] }
  end

  def start_close_label
    if allday?
      start_date = I18n.l(start_at.to_date, format: :long)
      close_date = I18n.l(close_at.to_date, format: :long)

      if start_date == close_date
        start_date
      else
        "#{start_date}#{I18n.t("ss.wave_dash")}#{close_date}"
      end
    else
      start_date = I18n.l(start_at.to_date, format: :long)
      close_date = I18n.l(close_at.to_date, format: :long)
      start_time = "#{start_at.hour}:#{format('%02d', start_at.minute)}"
      close_time = "#{close_at.hour}:#{format('%02d', close_at.minute)}"

      if start_date == close_date
        "#{start_date} #{start_time}#{I18n.t("ss.wave_dash")}#{close_time}"
      else
        "#{start_date} #{start_time}#{I18n.t("ss.wave_dash")} #{close_date} #{close_time}"
      end
    end
  end

  def allday?
    allday == "allday"
  end

  def paid_leave?
    leave_type == "paid"
  end

  def leave_type_options
    Gws::Affair2::LeaveSetting.leave_type_options
  end

  def initialize_in_accessor
    if start_at
      self.in_start_date = start_at.to_date
      self.in_start_hour = start_at.hour
      self.in_start_minute = start_at.min
    end
    if close_at
      self.in_close_date = close_at.to_date
      self.in_close_hour = close_at.hour
      self.in_close_minute = close_at.min
    end
  end

  alias in_start_hour_options hour_options
  alias in_start_minute_options minute_options
  alias in_close_hour_options hour_options
  alias in_close_minute_options minute_options

  private

  def set_long_name
    self.long_name = "#{name}（#{start_close_label}）"
  end

  def set_start_close
    if allday?
      if in_start_date
        self.start_at = Time.zone.parse(in_start_date).change(hour: 0, min: 0, sec: 0) rescue nil
      end
      if in_close_date
        self.close_at = Time.zone.parse(in_close_date).change(hour: 0, min: 0, sec: 0).end_of_day rescue nil
      end
    else
      self.in_close_date = in_start_date
      if in_start_date && in_start_hour && in_start_minute
        self.start_at = Time.zone.parse(in_start_date).change(hour: in_start_hour.to_i, min: in_start_minute, sec: 0) rescue nil
      end
      if in_close_date && in_close_hour && in_close_minute
        self.close_at = Time.zone.parse(in_start_date).change(hour: in_close_hour.to_i, min: in_close_minute, sec: 0) rescue nil
      end
    end
  end

  def validate_records
    @record_validator = Gws::Affair2::Leave::RecordValidator.new(self)
    @record_validator.validate
  end

  def save_records
    records.destroy_all
    return if @record_validator.nil?
    @record_validator.records.each do |record|
      record.file = self
      record.save!
    end
  end

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
