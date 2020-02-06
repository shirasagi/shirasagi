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
    field :hostname, type: String
    field :ip_address, type: String
    field :process_id, type: Integer
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

  module ClassMethods
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria = criteria.search_ymd(params)
      criteria = criteria.search_class_name(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :class_name, :logs)
    end

    def search_ymd(params)
      return all if params[:term] == 'all_save'
      return all if params[:ymd].blank?

      ymd = params[:ymd]
      return all if ymd.length != 8

      started_at = Time.zone.local(ymd[0..3].to_i, ymd[4..5].to_i, ymd[6..7].to_i)
      end_at = started_at.end_of_day
      from = term_to_date(params[:term] || 'day', end_at)

      all.gte(updated: from).lte(updated: end_at)
    end

    def search_class_name(params)
      return all if params[:class_name].blank?
      all.where(class_name: params[:class_name])
    end
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

  def head_logs(limit = 1_000)
    if file_path && ::File.exists?(file_path)
      texts = []
      ::File.open(file_path) do |f|
        limit.times do
          line = f.gets || break
          texts << line
        end
      end
      texts
    else
      []
    end
  end

  def logs
    if ::Fs.mode == :file && ::File.exists?(file_path)
      return ::File.readlines(file_path) rescue []
    end

    self[:logs]
  end

  module ClassMethods
    def term_to_date(name, date = Time.zone.now)
      num, unit = name.to_s.split('.')
      if unit.blank?
        unit, num = num, unit
      end
      num = 1 if !num.numeric?
      num = num.to_i

      case unit.singularize
      when "year"
        date - num.years
      when "month"
        date - num.months
      when "week"
        date - num.weeks
      when "day"
        date - num.days
      when "all_delete"
        date
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
