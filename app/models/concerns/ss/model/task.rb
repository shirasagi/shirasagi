module SS::Model::Task
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  # include SS::Reference::Site
  include SS::Reference::User

  attr_accessor :log_buffer

  included do
    store_in collection: "ss_tasks"
    store_in_repl_master

    attr_accessor :cur_site

    seqid :id
    belongs_to :site, class_name: "SS::Site"
    field :name, type: String
    # field :command, type: String
    field :state, type: String, default: "stop"
    field :interrupt, type: String
    field :started, type: DateTime
    field :closed, type: DateTime
    field :total_count, type: Integer, default: 0
    field :current_count, type: Integer, default: 0

    before_validation :set_site_id, if: ->{ @cur_site }

    validates :name, presence: true
    validates :state, presence: true
    validates :started, datetime: true
    validates :closed, datetime: true

    after_initialize :init_variables

    scope :site, ->(site) { where(site_id: site.id) }
  end

  class Interrupt < StandardError
  end

  module ClassMethods
    def ready(cond, &block)
      task = self.find_or_create_by(cond)
      return false unless task.start

      begin
        require 'benchmark'
        time = Benchmark.realtime { yield task }
        task.log sprintf("# %d sec\n\n", time)
      rescue Interrupt => e
        task.log "-- #{e}"
        # task.log e.backtrace.join("\n")
      rescue StandardError => e
        task.log "-- Error"
        task.log e.to_s
        task.log e.backtrace.join("\n")
      end
      task.close
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

  def running?
    state == "running"
  end

  def start
    if running?
      Rails.logger.info "already running."
      return false
    end

    change_state("running", { started: Time.zone.now })
  end

  def ready
    if running?
      Rails.logger.info "already running."
      return false
    end
    if state == "ready"
      Rails.logger.info "already ready."
      return false
    end

    change_state("ready")
  end

  def close
    self.closed = Time.zone.now
    self.state  = "stop"
    result = save

    if result && @log_file
      @log_file.close
      @log_file = nil
    end

    result
  end

  def clear_log(msg = nil)
    if @log_file
      @log_file.close
      @log_file = nil
    end

    self.unset(:logs) if self[:logs].present?

    ::FileUtils.rm_f(log_file_path) if log_file_path && ::File.exists?(log_file_path)
  end

  def log_file_path
    return if new_record?
    @log_file_path ||= "#{SS::File.root}/ss_tasks/" + id.to_s.split(//).join("/") + "/_/#{id}.log"
  end

  def logs
    if log_file_path && ::File.exists?(log_file_path)
      return ::File.readlines(log_file_path, chomp: true) rescue []
    end

    self[:logs] || []
  end

  def head_logs(n = 1_000)
    if log_file_path && ::File.exists?(log_file_path)
      texts = []
      open(log_file_path) do |f|
        n.times do
          line = f.gets || break
          texts << line.chomp
        end
      end
      texts
    elsif self[:logs].present?
      self[:logs][0..(n - 1)]
    else
      []
    end
  end

  def log(msg)
    @log_file ||= begin
      dirname = ::File.dirname(log_file_path)
      ::FileUtils.mkdir_p(dirname) unless ::Dir.exists?(dirname)

      file = ::File.open(log_file_path, 'a')
      file.sync = true
      file
    end

    puts msg
    @log_file.puts msg
    Rails.logger.info msg
  end

  def process(controller, action, params = {})
    agent = SS::Agent.new controller
    agent.controller.instance_variable_set :@task, self
    params.each do |k, v|
      agent.controller.instance_variable_set :"@#{k}", v
    end
    agent.invoke action
  end

  private

  def set_site_id
    self.site_id ||= @cur_site.id
  end

  def change_state(state, attrs = {})
    self.started       = attrs[:started]
    self.closed        = nil
    self.state         = state
    self.interrupt     = nil
    self.total_count   = 0
    self.current_count = 0
    result = save

    clear_log if result

    result
  end
end
