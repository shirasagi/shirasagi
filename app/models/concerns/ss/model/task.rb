module SS::Model::Task
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User

  STATE_STOP = "stop".freeze
  STATE_READY = "ready".freeze
  STATE_RUNNING = "running".freeze
  STATE_COMPLETED = "completed".freeze
  STATE_FAILED = "failed".freeze
  STATE_INTERRUPTED = "interrupted".freeze

  RUN_EXPIRATION = 2.hours

  included do
    store_in collection: "ss_tasks"
    store_in_repl_master

    self.site_required = false

    attr_accessor :log_buffer

    seqid :id
    field :name, type: String
    # field :command, type: String
    field :state, type: String, default: STATE_STOP
    field :interrupt, type: String
    field :started, type: DateTime
    field :closed, type: DateTime
    field :at, type: Integer
    field :total_count, type: Integer, default: 0
    field :current_count, type: Integer, default: 0
    field :segment, type: String

    validates :name, presence: true
    validates :state, presence: true
    validates :started, datetime: true
    validates :closed, datetime: true

    after_initialize :init_variables
    after_destroy ->{ ::FileUtils.rm_rf(base_dir) }
  end

  class Interrupt < StandardError
  end

  class TaskLogFormatter
    class << self
      def default
        self
      end

      def call(_severity, _time, _progname, msg)
        msg
      end
    end
  end

  module ClassMethods
    def ready(cond, &block)
      task = self.find_or_create_by(cond)
      task.run_with(rejected: ->{ false }) do
        yield task if block_given?
      end
    end

    def search(params)
      all.search_keyword(params).search_site(params).search_state(params)
    end

    def search_keyword(params)
      return all if params.blank || params[:keyword].blank?

      all.keyword_in(params[:keyword], :name)
    end

    def search_site(params)
      return all if params.blank || params[:site_id].blank?

      all.where(site_id: params[:site_id])
    end

    def search_state(params)
      return all if params.blank || params[:state].blank?

      all.where(state: params[:state])
    end
  end

  def count(other = 1)
    self.current_count += other
    if (self.current_count % log_buffer) == 0
      save
      interrupt = self.class.find_by(id: id, select: interrupt).interrupt
      raise Interrupt, "interrupted: stop" if interrupt.to_s == "stop"
      # GC.start
    end
    self
  end

  def init_variables
    self.log_buffer = 50
  end

  def ready?(limit = nil)
    limit ||= RUN_EXPIRATION
    state == STATE_READY && (started.presence || updated) + limit > Time.zone.now
  end

  def running?(limit = nil)
    limit ||= RUN_EXPIRATION
    state == STATE_RUNNING && (started.presence || updated) + limit > Time.zone.now
  end

  def start
    if running?
      Rails.logger.info "already running."
      return false
    end

    if_states = [ STATE_STOP, STATE_READY, STATE_COMPLETED, STATE_FAILED, STATE_INTERRUPTED ]
    change_state(STATE_RUNNING, started: Time.zone.now, if_states: if_states)
  end

  def ready
    if running?
      Rails.logger.info "already running."
      return false
    end
    if ready?
      Rails.logger.info "already ready."
      return false
    end
    unless ApplicationJob.check_size_limit_per_user?(user_id)
      Rails.logger.info I18n.t('job.notice.size_limit_exceeded')
      return false
    end

    change_state(STATE_READY, if_states: [ STATE_STOP, STATE_COMPLETED, STATE_FAILED, STATE_INTERRUPTED ])
  end

  def close(state = STATE_STOP)
    self.closed = Time.zone.now
    self.state  = state
    result = save

    if result
      if @logger
        @logger.close rescue nil
        @logger = nil
      end

      if @log_file
        @log_file.close rescue nil
        @log_file = nil
      end

      if @performance
        @performance.close rescue nil
        @performance = nil
      end
    end

    result
  end

  def run_with(resolved: nil, rejected: nil, &block)
    ret = nil
    if !start
      ret = rejected.call if rejected
      return ret
    end

    resolved ||= block

    begin
      ret = resolved.call
    rescue Interrupt => e
      log "-- #{e}"
      close(STATE_INTERRUPTED)
      raise
    rescue Exception => e
      log "-- Error"
      log e.to_s
      log e.backtrace.join("\n")
      close(STATE_FAILED)
      raise
    else
      close(STATE_COMPLETED)
    end

    ret
  end

  def clear_log(msg = nil)
    if @logger
      @logger.close rescue nil
      @logger = nil
    end

    if @log_file
      @log_file.close rescue nil
      @log_file = nil
    end

    self.unset(:logs) if self[:logs].present?

    ::FileUtils.rm_f(log_file_path) if log_file_path && ::File.exist?(log_file_path)
  end

  def base_dir
    return if new_record?
    @base_dir ||= "#{SS::File.root}/ss_tasks/#{id.to_s.chars.join("/")}/_"
  end

  def log_file_path
    return if new_record?
    @log_file_path ||= "#{base_dir}/#{id}.log"
  end

  def perf_log_file_path
    return if log_file_path.blank?
    log_file_path.sub(".log", "") + "-performance.log.gz"
  end

  def logs
    if log_file_path && ::File.exist?(log_file_path)
      return ::File.readlines(log_file_path, chomp: true) rescue []
    end

    []
  end

  def head_logs(num_logs = nil)
    Fs.head_lines(log_file_path, limit: num_logs)
  end

  def logger
    @log_file ||= begin
      dirname = ::File.dirname(log_file_path)
      ::FileUtils.mkdir_p(dirname) unless ::Dir.exist?(dirname)

      file = ::File.open(log_file_path, 'a')
      # file = ::File.open(log_file_path, (File::WRONLY | File::APPEND))
      file.sync = true
      file
    end

    @logger ||= begin
      base_logger = ActiveSupport::Logger.new(@log_file, formatter: TaskLogFormatter.default)
      stdout_logger = ActiveSupport::Logger.new($stdout, formatter: TaskLogFormatter.default)
      def stdout_logger.close
        # do not close $stdout
      end

      base_logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
      ActiveSupport::TaggedLogging.new(base_logger)
    end
  end

  def log(msg)
    logger.info msg
    Rails.logger.info msg
  end

  def tagged(name, &block)
    logger.tagged(name) do
      Rails.logger.tagged(name, &block)
    end
  end

  def process(controller, action, params = {})
    if !controller.is_a?(String)
      controller = controller.name.underscore.sub('_controller', '')
    end
    SS::Agent.invoke_action(controller, action, params.merge(task: self))
  end

  def performance
    @performance ||= SS::Task::PerformanceCollector.new(self)
  end

  private

  def change_state(state, attrs = {})
    raise "first of all, you must save." if new_record?

    expired_at = attrs[:started].try { |time| time.in_time_zone } || Time.zone.now
    expired_at -= RUN_EXPIRATION

    cond = [
      { state: { "$in" => attrs[:if_states] } },
      { updated: { "$lte" => expired_at.utc } }
    ]
    updates = {
      state: state, started: attrs[:started].try { |time| time.in_time_zone.utc }, closed: nil, interrupt: nil,
      total_count: 0, current_count: 0
    }

    criteria = self.class.where(id: id, "$and" => [{ "$or" => cond }])
    task = criteria.find_one_and_update({ '$set' => updates }, return_document: :after)
    return false if task.blank?

    self.reload
    clear_log

    true
  end
end
