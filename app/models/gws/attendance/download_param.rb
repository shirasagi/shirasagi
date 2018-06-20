class Gws::Attendance::DownloadParam
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :cur_site, :cur_user
  attr_accessor :from_date, :to_date, :user_ids, :encoding

  permit_params :from_date, :to_date, :encoding
  permit_params user_ids: []

  validate :validate_from_date
  validate :validate_to_date
  validate :validate_user_ids
  validates :encoding, presence: true

  class << self
    def t(*args)
      human_attribute_name(*args)
    end

    def tt(key, html_wrap = true)
      modelnames = ancestors.select { |x| x.respond_to?(:model_name) }
      msg = ""
      modelnames.each do |modelname|
        msg = I18n.t("tooltip.#{modelname.model_name.i18n_key}.#{key}", default: "")
        break if msg.present?
      end
      return msg if msg.blank? || !html_wrap
      msg = [msg] if msg.class.to_s == "String"
      list = msg.map { |d| "<p>" + d.to_s.gsub(/\r\n|\n/, "<br />") + "<br /></p>" }

      h = []
      h << %(<div class="ss-tooltip">?)
      h << %(<button class="ss-tooltip-toggle" tabindex="-1"><i class="material-icons">help</i></button>)
      h << %(<div class="ss-tooltip-body">)
      h << list
      h << %(<div class="popper__arrow" x-arrow></div>)
      h << %(</div>)
      h << %(</div>)
      h.join("\n").html_safe
    end
  end

  private

  def validate_user_ids
    if user_ids.present?
      self.user_ids = user_ids.select(&:present?).map(&:to_i)
    end

    if user_ids.blank?
      errors.add :user_ids, :blank
    end
  end

  def validate_from_date
    if from_date.blank?
      errors.add :from_date, :blank
      return
    end

    self.from_date = Time.zone.parse(self.from_date.to_s)
    if self.from_date == ::Date::EPOCH || self.from_date == ::Time::EPOCH
      errors.add :from_date, :invalid
    end
  end

  def validate_to_date
    if to_date.blank?
      errors.add :to_date, :blank
      return
    end

    self.to_date = Time.zone.parse(self.to_date.to_s)
    if self.to_date == ::Date::EPOCH || self.to_date == ::Time::EPOCH
      errors.add :to_date, :invalid
    end
  end
end
