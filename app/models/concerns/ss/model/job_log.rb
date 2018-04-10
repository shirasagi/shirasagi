module SS::Model::JobLog
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  STATE_RUNNING = "running".freeze
  STATE_COMPLETED = "completed".freeze
  STATE_FAILED = "failed".freeze

  included do
    store_in collection: "job_logs"
    store_in_repl_master

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

    validates :job_id, presence: true
    validates :state, presence: true
    validates :pool, presence: true
    validates :class_name, presence: true

    after_destroy :destroy_files

    scope :term, ->(from) { where(:created.lt => from) }
  end

  def save_term_options
    %w(day month year all_save).map do |v|
      [ I18n.t("history.save_term.#{v}"), v ]
    end
  end

  def delete_term_options
    %w(6.months 3.months 2.months month 2.weeks week all_delete).map do |v|
      [ I18n.t("history.save_term.#{v.sub('.', '_')}"), v ]
    end
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

  def file_path
    raise if new_record?
    @file_path ||= "#{SS::File.root}/job_logs/" + id.to_s.split(//).join("/") + "/_/#{id}.log"
  end

  def logs
    if ::Fs.mode == :file && ::File.exists?(file_path)
      return ::File.readlines(file_path) rescue []
    end

    self[:logs]
  end

  module ClassMethods
    def term_to_date(name)
      num, unit = name.to_s.split('.')
      if unit.blank?
        unit, num = num, unit
      end
      num = 1 if !num.numeric?
      num = num.to_i

      case unit.singularize
      when "year"
        Time.zone.now - num.years
      when "month"
        Time.zone.now - num.months
      when "week"
        Time.zone.now - num.weeks
      when "day"
        Time.zone.now - num.days
      when "all_delete"
        Time.zone.now
      when "all_save"
        nil
      else
        raise "malformed term: #{name}"
      end
    end
  end

  private

  def destroy_files
    if ::Fs.mode == :file && ::File.exists?(file_path)
      dirname = ::File.dirname(file_path)
      ::FileUtils.rm_rf(dirname)
    end
  end
end
