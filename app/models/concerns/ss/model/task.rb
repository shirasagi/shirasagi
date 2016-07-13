module SS::Model::Task
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  # include SS::Reference::Site
  include SS::Reference::User

  attr_accessor :log_buffer

  included do
    store_in collection: "ss_tasks"

    attr_accessor :cur_site

    seqid :id
    belongs_to :site, class_name: "SS::Site"
    field :name, type: String
    #field :command, type: String
    field :state, type: String, default: "stop"
    field :interrupt, type: String
    field :started, type: DateTime
    field :closed, type: DateTime
    field :total_count, type: Integer, default: 0
    field :current_count, type: Integer, default: 0
    field :logs, type: Array, default: []

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
        #task.log e.backtrace.join("\n")
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
      #GC.start
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
      log "already running."
      return false
    end

    self.started       = Time.zone.now
    self.closed        = nil
    self.state         = "running"
    self.interrupt     = nil
    self.total_count   = 0
    self.current_count = 0
    self.logs          = []
    save
  end

  def close
    self.closed = Time.zone.now
    self.state  = "stop"
    save
  end

  def clear_log(msg = nil)
    self.logs = []
    self.logs << msg if msg
  end

  def log(msg)
    puts msg
    Rails.logger.info msg
    self.logs << msg
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
end
