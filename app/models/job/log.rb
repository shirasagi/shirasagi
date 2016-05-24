class Job::Log
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  #include SS::Reference::Site

  STATE_RUNNING = "running".freeze
  STATE_COMPLETED = "completed".freeze
  STATE_FAILED = "failed".freeze

  index({ updated: -1 })

  attr_accessor :save_term

  seqid :id
  field :job_id, type: String
  field :state, type: String
  field :started, type: DateTime
  field :closed, type: DateTime
  field :logs, type: Array, default: []
  field :pool, type: String
  field :class_name, type: String
  field :args, type: Array
  field :priority, type: Integer
  field :at, type: Integer

  belongs_to :site, class_name: "SS::Site"

  validates :job_id, presence: true
  validates :state, presence: true
  validates :pool, presence: true
  validates :class_name, presence: true

  scope :site, ->(site) { where(site_id: (site.nil? ? nil : site.id)) }
  scope :term, ->(from) { where(:created.lt => from) }

  def save_term_options
    [
      [I18n.t(:"history.save_term.day"), "day"],
      [I18n.t(:"history.save_term.month"), "month"],
      [I18n.t(:"history.save_term.year"), "year"],
      [I18n.t(:"history.save_term.all_save"), "all_save"],
    ]
  end

  def delete_term_options
    [
      [I18n.t(:"history.save_term.year"), "year"],
      [I18n.t(:"history.save_term.month"), "month"],
      [I18n.t(:"history.save_term.all_delete"), "all_delete"],
    ]
  end

  def start_label
    started ? started.strftime("%Y-%m-%d %H:%M") : ""
  end

  def closed_label
    closed ? closed.strftime("%Y-%m-%d %H:%M") : ""
  end

  def joined_jobs
    logs.blank? ? '' : logs.join("\n")
  end

  class << self
    def add(task)
      # copy all members
      log = Job::Log.new(
        site_id: task.site_id,
        user_id: task.user_id,
        job_id: task.id,
        state: task.state,
        started: task.started,
        closed: task.closed,
        logs: task.logs,
        pool: task.pool,
        class_name: task.class_name,
        args: task.args,
        priority: task.priority,
        at: task.at)
      log.save!
      log
    end

    def create_from_active_job(job)
      self.create(
        site_id: job.try(:site_id),
        user_id: job.try(:user_id),
        job_id: job.job_id,
        state: 'stop',
        pool: job.queue_name,
        class_name: job.class.name,
        args: job.arguments
      )
    end

    def term_to_date(name)
      case name.to_s
      when "year"
        Time.zone.now - 1.year
      when "month"
        Time.zone.now - 1.month
      when "day"
        Time.zone.now - 1.day
      when "all_delete"
        Time.zone.now
      when "all_save"
        nil
      else
        raise "malformed term: #{name}"
      end
    end
  end
end
