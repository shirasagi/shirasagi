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
    field :state, type: String
    field :started, type: DateTime
    field :closed, type: DateTime
  end

  public
    def running?
      state == "running"
    end

    def start
      return false if running?

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

    def log
      Fs.exists?(log_file) ? Fs.read(log_file).force_encoding("utf-8") : nil
    end

    def log_file
      return @log if @log
      @log = "#{Rails.root}/log/tasks/#{id.to_s.split(//).join('/')}/_/#{name.gsub(/\W/, '_')}.log"
    end

    def puts_log(msg)
      dump msg if Rails.env.development?
      File.open(log_file, "a") { |file| file.puts msg.force_encoding("utf-8").strip }
    end

    def clear_log
      dir = File.dirname(log_file)
      Fs.mkdir_p(dir) unless Fs.exists?(dir)
      Fs.write log_file, ""
    end

    def run(&block)
      if start
        clear_log
        begin
          puts_log "run #{name}.."
          yield
          puts_log "end."
        rescue => e
          puts_log e.to_s
        end
        close
      end
    end
end
