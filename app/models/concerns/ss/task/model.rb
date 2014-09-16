# coding: utf-8
module SS::Task::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  included do
    store_in collection: "ss_tasks"

    seqid :id
    field :name, type: String
    #field :command, type: String
    field :state, type: String, default: "stop"
    field :started, type: DateTime
    field :closed, type: DateTime

    validates :name, presence: true
    validates :state, presence: true
  end

  module ClassMethods
    public
      def run(cond, &block)
        task = Cms::Task.find_or_create_by(cond)
        return puts "already running. ##{cond[:name]}" unless task.start

        begin
          require 'benchmark'
          time = Benchmark.realtime { yield task }
          task.log sprintf("(%.3fms)", time)
        rescue StandardError => e
          task.log e.to_s
          task.log e.backtrace.join("\n")
          dump "#{e.to_s}\n#{e.backtrace.join("\n")}" if Rails.env.development?
        end
        task.close
      end
  end

  public
    def running?
      state == "running"
    end

    def start
      return false if running?
      @logs = []

      self.started = Time.now
      self.closed  = nil
      self.state   = "running"
      save
    end

    def close
      self.closed = Time.now
      self.state  = "stop"
      save
    end

    def log_file
      "#{Rails.root}/log/tasks/#{id.to_s.split(//).join('/')}/_/#{name.gsub(/\W/, '_')}.log"
    end

    def read_log
      Fs.exists?(log_file) ? Fs.read(log_file).force_encoding("utf-8") : nil
    end

    def log(msg)
      @logs << msg
      puts msg
      dump msg if Rails.env.development?
    end

    def log_dump
      dir = File.dirname(log_file)
      Fs.mkdir_p(dir) unless Fs.exists?(dir)
      Fs.write log_file, @logs.join("\n")
    end
end
