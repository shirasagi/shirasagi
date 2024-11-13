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
      all.keyword_in(params[:keyword], :job_id, :hostname, :ip_address, :class_name)
    end

    def search_ymd(params)
      return all if params[:term].blank? || params[:term] == 'all_save'
      return all if params[:ymd].blank?

      ymd = params[:ymd]
      return all if ymd.length != 8

      started_at = Time.zone.local(ymd[0..3].to_i, ymd[4..5].to_i, ymd[6..7].to_i)
      end_at = started_at.end_of_day
      from = end_at - SS::Duration.parse(params[:term])

      all.gte(updated: from).lte(updated: end_at)
    end

    def search_class_name(params)
      return all if params[:class_name].blank?
      all.where(class_name: params[:class_name])
    end

    def used_size
      size = all.total_bsonsize
      ids = all.pluck(:id)
      ids.each do |id|
        Dir["#{SS::File.root}/job_logs/" + id.to_s.chars.join("/") + "/_/*"].each do |path|
          if ::File.file?(path)
            size += ::File.size(path) rescue 0
          end
        end
      end
      size
    end
  end

  def save_term_options
    %w(1.day 1.month 1.year).map do |v|
      [ I18n.t("ss.options.duration.#{v.sub('.', '_')}"), v ]
    end
  end

  def delete_term_options
    %w(6.months 3.months 2.months 1.month 2.weeks 1.week).map do |v|
      [ I18n.t("ss.options.duration.#{v.sub('.', '_')}"), v ]
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
    @file_path ||= "#{SS::File.root}/job_logs/" + id.to_s.chars.join("/") + "/_/#{id}.log"
  end

  def head_logs(limit = nil)
    Fs.head_lines(file_path, limit: limit)
  end

  def logs
    if ::Fs.mode == :file && ::File.exist?(file_path)
      return ::File.readlines(file_path) rescue []
    end

    self[:logs]
  end

  private

  def destroy_files
    if ::Fs.mode == :file && ::File.exist?(file_path)
      dirname = ::File.dirname(file_path)
      ::FileUtils.rm_rf(dirname)
    end
  end
end
