class Gws::Workload::Work
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Workload::Yearly
  include Gws::Addon::Workload::CommentPost
  #include Gws::Addon::Reminder
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Workload::Member
  include Gws::Workload::ScheduleCalendar
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # index({ site_id: 1, post_id: 1, deleted: 1 })
  # index({ due_date: 1, site_id: 1, post_id: 1, deleted: 1 })
  # index({ updated: 1, site_id: 1, post_id: 1, deleted: 1 })
  # index({ created: 1, site_id: 1, post_id: 1, deleted: 1 })

  permission_include_custom_groups

  seqid :id

  field :name, type: String

  # 期間内(due_start_on - due_end_on) の年度・月
  field :year_months, type: Array, default: []

  field :due_date, type: DateTime
  field :due_start_on, type: DateTime
  field :due_end_on, type: DateTime
  field :state, type: String, default: 'public' # not used
  field :achievement_rate, type: Integer, default: 0
  field :worktime_minutes, type: Integer, default: 0
  field :work_state, type: String, default: 'unfinished'

  belongs_to :category, class_name: "Gws::Workload::Category"
  belongs_to :client, class_name: "Gws::Workload::Client"
  belongs_to :cycle, class_name: "Gws::Workload::Cycle"
  belongs_to :load, class_name: "Gws::Workload::Load"

  permit_params :name, :due_date, :due_start_on, :due_end_on, :deleted
  permit_params :category_id, :client_id, :cycle_id, :load_id

  validates :name, presence: true
  validate :validate_due_date

  # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::WorkloadWorkJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::WorkloadWorkJob.callback

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      all.reorder(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      all.reorder(updated: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('due_date')
      all.reorder(due_date: key.end_with?('_asc') ? 1 : -1)
    else
      all
    end
  }

  def sort_options
    %w(due_date_desc due_date_asc updated_desc updated_asc created_desc created_asc).map do |k|
      [I18n.t("gws/workload.options.sort.#{k}"), k]
    end
  end

  def work_state_options
    %w(finished except_finished all).map do |k|
      [I18n.t("gws/workload.options.work_state.#{k}"), k]
    end
  end

  def worktime_label
    return if worktime_minutes == 0
    hours = worktime_minutes / 60
    minutes = worktime_minutes % 60
    format("%d:%02d", hours, minutes)
  end

  def subscribed_users
    return Gws::User.none if new_record?
    members
  end

  class << self
    def readable_or_manageable(user, opts = {})
      or_cond = Array[readable_conditions(user, opts)].flatten.compact
      or_cond << allow_condition(:read, user, site: opts[:site])
      where("$and" => [{ "$or" => or_cond }])
    end

    def search(params)
      criteria = all
      criteria = criteria.search_year(params)
      criteria = criteria.search_keyword(params)
      criteria = criteria.search_category_id(params)
      criteria = criteria.search_client_id(params)
      criteria = criteria.search_work_state(params)
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_category_id(params)
      return all if params.blank? || params[:category_id].blank?

      all.where(category_id: params[:category_id])
    end

    def search_client_id(params)
      return all if params.blank? || params[:client_id].blank?

      all.where(client_id: params[:client_id])
    end

    def search_work_state(params)
      work_state = params[:work_state].presence rescue nil

      if work_state.blank? || work_state == 'all'
        all
      elsif work_state == "except_finished"
        all.not_in(work_state: %w(finished))
      else
        all.where(work_state: work_state)
      end
    end
  end

  def active?
    !deleted?
  end

  def deleted?
    deleted.present? && deleted <= Time.zone.now
  end

  private

  def validate_due_date
    errors.add :due_date, :blank if due_date.blank?
    errors.add :due_start_on, :blank if due_start_on.blank?
    return if errors.present?

    if due_start_on > due_date
      errors.add :due_date, :greater_than, count: t(:due_start_on)
    end
    if due_end_on && due_start_on > due_end_on
      errors.add :due_end_on, :greater_than, count: t(:due_start_on)
    end
    if due_end_on && due_end_on > due_date
      errors.add :due_date, :greater_than, count: t(:due_end_on)
    end
    return if errors.present?

    self.year_months = []
    d1 = due_start_on.dup.change(day: 1)
    d2 = due_end_on ? due_end_on.dup.change(day: 1) : d1.dup
    while (true) do
      self.year_months << {
        "year" => (@cur_site || site).fiscal_year(d1),
        "month" => d1.month
      }
      d1 = d1.advance(months: 1)
      break if d1 > d2
    end

    if !year_months.map { |h| h["year"] }.include?(year)
      errors.add :year, "が #{t(:due_start_on)} 〜 #{t(:due_end_on)} の期間に含まれていません"
    end
  end
end
