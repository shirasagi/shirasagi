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

    # set TTL index
    index({ updated: -1 }, { expire_after_seconds: 2.weeks })

    attr_accessor :save_term

    seqid :id
    field :job_id, type: String
    field :state, type: String
    field :started, type: DateTime
    field :closed, type: DateTime
    # field :logs, type: Array, default: []
    field :log, type: String
    field :pool, type: String
    field :class_name, type: String
    field :args, type: Array
    field :priority, type: Integer
    field :at, type: Integer

    validates :job_id, presence: true
    validates :state, presence: true
    validates :pool, presence: true
    validates :class_name, presence: true

    scope :term, ->(from) { where(:created.lt => from) }
  end

  def save_term_options
    %w(day month year all_save).map do |v|
      [ I18n.t(:"history.save_term.#{v}"), v ]
    end
  end

  def delete_term_options
    %w(year month all_delete).map do |v|
      [ I18n.t(:"history.save_term.#{v}"), v ]
    end
  end

  def start_label
    started ? I18n.l(started, format: :iso) : ""
  end

  def closed_label
    closed ? I18n.l(closed, format: :iso) : ""
  end

  # def joined_jobs
  #   return log if log.present?
  #   return logs.join("\n") if logs.present?
  #   ''
  # end
  #
  # def logs
  #   attributes[:logs]
  # end

  module ClassMethods
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
