class Gws::Workload::WorkComment
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Addon::Markdown

  attr_accessor :cur_work
  attr_accessor :in_worktime_hours, :in_worktime_minutes

  belongs_to :work, class_name: 'Gws::Workload::Work'

  field :commented_at, type: DateTime
  field :year, type: Integer
  field :month, type: Integer
  field :day, type: Integer
  field :achievement_rate, type: Integer
  field :worktime_minutes, type: Integer, default: 0

  permit_params :commented_at, :achievement_rate
  permit_params :in_worktime_hours, :in_worktime_minutes

  before_validation :set_work_id, if: ->{ @cur_work }
  before_validation :set_worktime_minutes
  before_validation :set_commented_at

  validates :work_id, presence: true
  validates :commented_at, presence: true
  validates :achievement_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_blank: true }
  validates :text, presence: true, if: -> { achievement_rate.blank? && worktime_minutes == 0 }

  default_scope ->{ order_by(commented_at: 1) }

  scope :and_work, ->(work) { where( work_id: work.id ) }

  delegate :subscribed_users, to: :work

  def in_worktime_hours_options
    (0..40).map { |h| [h, h] }
  end

  def in_worktime_minutes_options
    (0..59).map { |m| [m, m] }
  end

  def worktime_label
    return if worktime_minutes == 0
    hours = worktime_minutes / 60
    minutes = worktime_minutes % 60
    format("%d:%02d", hours, minutes)
  end

  private

  def set_work_id
    self.work_id ||= @cur_work.id
  end

  def set_worktime_minutes
    return if in_worktime_hours.nil? || in_worktime_minutes.nil?
    self.worktime_minutes = (in_worktime_hours.to_i * 60) + in_worktime_minutes.to_i
  end

  def set_commented_at
    self.commented_at ||= updated
    self.year = (@cur_site || site).fiscal_year(commented_at)
    self.month = commented_at.month
    self.day = commented_at.day
  end
end
