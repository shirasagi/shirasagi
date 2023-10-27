class Gws::Facility::Item
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Scope::ActivationDate
  include SS::Addon::Markdown
  include Gws::Addon::Facility::ColumnSetting
  include Gws::Addon::Facility::ReservableSetting
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Addon::Import::Facility::Item

  MINUTES_LIMIT_MAX_BASE = 10_080 * 100

  store_in collection: "gws_facilities"

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :activation_date, type: DateTime
  field :expiration_date, type: DateTime
  field :min_minutes_limit, type: Integer
  field :max_minutes_limit, type: Integer
  field :max_days_limit, type: Integer
  field :reservation_start_date, type: DateTime
  field :reservation_end_date, type: DateTime
  field :approval_check_state, type: String, default: 'disabled'

  belongs_to :category, class_name: 'Gws::Facility::Category'

  permit_params :name, :order, :category_id, :activation_date, :expiration_date
  permit_params :min_minutes_limit, :max_minutes_limit, :max_days_limit
  permit_params :reservation_start_date, :reservation_end_date
  permit_params :approval_check_state

  validates :name, presence: true, length: { maximum: 80 }
  validates :activation_date, datetime: true
  validates :expiration_date, datetime: true
  validates :min_minutes_limit, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MINUTES_LIMIT_MAX_BASE, allow_blank: true
  }
  validates :max_minutes_limit, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MINUTES_LIMIT_MAX_BASE, allow_blank: true
  }
  validates :max_days_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  validates :reservation_start_date, datetime: true
  validates :reservation_end_date, datetime: true
  validates :approval_check_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
  validate :validate_minutes_limit
  validate :validate_approval_check_state, if: ->{ approval_check_state == 'enabled' }

  default_scope -> { order_by order: 1, name: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:category].present?
      criteria = criteria.where(category_id: params[:category])
    end

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :text
    end
    criteria
  }
  scope :category_id, ->(category_id) do
    if category_id.present?
      where category_id: category_id.id
    else
      where({})
    end
  end

  def category_options
    site = @cur_site || self.site
    user = @cur_user || self.user
    @category_options ||= Gws::Facility::Category.site(site).readable(user, site: site).
      map { |c| [c.name, c.id] }
  end

  def approval_check_state_options
    %w(enabled disabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def approval_check?
    approval_check_state == "enabled"
  end

  private

  def validate_minutes_limit
    return if min_minutes_limit.blank?
    return if max_minutes_limit.blank?
    return if min_minutes_limit <= max_minutes_limit

    errors.add :max_minutes_limit, :greater_than, count: t(:min_minutes_limit)
  end

  def validate_approval_check_state
    errors.add(:base, I18n.t('gws/facility.errors.require_approver')) if user_ids.blank?
  end
end
