class Cms::Line::DeliverPlan
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::Line::DeliverPlan::Repeat
  include Cms::Addon::GroupPermission

  set_permission_name "cms_line_messages", :use

  attr_accessor :in_ready

  field :name, type: String
  field :deliver_date, type: DateTime
  field :state, type: String, default: "ready"
  belongs_to :message, class_name: "Cms::Line::Message", inverse_of: :deliver_plans
  permit_params :deliver_date

  before_validation :set_name
  before_validation :set_state, if: ->{ in_ready }

  validates :deliver_date, presence: true
  validates :message_id, presence: true

  default_scope -> { order_by(deliver_date: 1) }

  def date
    deliver_date.to_date
  end

  def holiday?
    HolidayJapan.check(deliver_date)
  end

  def state_options
    %w(ready completed expired).map { |k| [I18n.t("cms.options.deliver_state.#{k}"), k] }
  end

  private

  def set_name
    return if deliver_date.blank?
    self.name = "#{deliver_date.strftime("%Y/%m/%d %H:%M")} (#{I18n.t("date.abbr_day_names")[deliver_date.wday]})"
  end

  def set_state
    return if deliver_date.blank?
    self.state = (deliver_date > Time.zone.now) ? "ready" : "expired"
  end

  class << self
    def search(params)
      criteria = all
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
