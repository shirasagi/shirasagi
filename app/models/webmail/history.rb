class Webmail::History
  include SS::Document
  include Webmail::Reference::User
  include Webmail::Permission

  if client = Mongoid::Config.clients[:webmail_history]
    store_in client: :webmail_history, database: client[:database]
  end

  seqid :id
  field :session_id, type: String
  field :request_id, type: String
  field :severity, type: String, default: 'error'
  field :name, type: String
  field :mode, type: String
  field :model, type: String
  field :controller, type: String
  field :job, type: String
  field :model_name, type: String
  field :job_name, type: String
  field :item_id, type: String
  field :path, type: String
  field :action, type: String
  field :message, type: String
  field :updated_fields, type: Array
  field :updated_field_names, type: Array

  with_options on: :model do
    validates :name, presence: true
    validates :mode, presence: true
    validates :model, presence: true
    validates :item_id, presence: true
  end
  with_options on: :controller do
    validates :controller, presence: true
    validates :path, presence: true
    validates :action, presence: true
  end
  with_options on: :job do
    validates :job, presence: true
    validates :action, presence: true
  end

  before_save :set_string_data

  default_scope -> {
    order_by created: -1
  }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria = criteria.search_ymd(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :session_id, :request_id, :name, :model_name, :user_name, :user_group_name)
    end

    def search_ymd(params)
      return all if params[:ymd].blank?

      ymd = params[:ymd]
      return all if ymd.length != 8

      started_at = Time.zone.local(ymd[0..3].to_i, ymd[4..5].to_i, ymd[6..7].to_i)
      end_at = started_at.end_of_day

      all.gte(created: started_at).lte(created: end_at)
    end

    def updated?
      where(mode: 'update').exists?
    end

    def error!(context, cur_user, attributes)
      write!(:error, context, cur_user, attributes)
    end

    def warn!(context, cur_user, attributes)
      write!(:warn, context, cur_user, attributes)
    end

    def info!(context, cur_user, attributes)
      write!(:info, context, cur_user, attributes)
    end

    def notice!(context, cur_user, attributes)
      if SS.config.webmail.history['severity_notice'] == 'enabled'
        write!(:notice, context, cur_user, attributes)
      end
    end

    def write!(severity, context, cur_user, attributes)
      item = new(
        cur_user: cur_user,
        session_id: Rails.application.current_session_id,
        request_id: Rails.application.current_request_id,
        severity: severity
      )
      item.attributes = attributes

      if allowed_severity = SS.config.webmail.history['severity']
        if severity_to_num(severity) >= severity_to_num(allowed_severity)
          item.save!(context: context.to_sym)
        end
      end

      try_invoke_archive(cur_user)
    end

    def create_controller_log!(request, response, options)
      return if request.format != 'text/html'

      if !request.get? && response.code =~ /^3/
        severity = 'info'
      else
        return if SS.config.webmail.history['severity_notice'] != 'enabled'
        severity = 'notice'
      end

      write!(
        severity, :controller, options[:cur_user],
        path: request.path, controller: options[:controller], action: options[:action]
      )
    end

    private

    # def encode_sjis(str)
    #   str.encode("SJIS", invalid: :replace, undef: :replace)
    # end

    def severity_to_num(severity)
      case severity.to_sym
      when :notice
        10
      when :info
        20
      when :warn
        30
      when :error
        40
      when :none
        999
      else
        0
      end
    end

    def try_invoke_archive(cur_user)
      return if rand <= 0.8
      return if !Webmail::HistoryArchiveJob.histories_to_archive?

      Webmail::HistoryArchiveJob.bind(user_id: cur_user).perform_later
    end
  end

  def model_name
    self[:model_name] || (model.present? ? I18n.t("mongoid.models.#{model}") : nil)
  end

  def controller_name
    controller
  end

  def job_name
    self[:job_name] || (job.present? ? I18n.t("job.models.#{job}") : nil)
  end

  def mode_name
    if mode.present?
      I18n.t("webmail.history.mode.#{mode}")
    end
  end

  def item
    @item ||= model.camelize.constantize.where(id: item_id).first
  end

  def module_key
    base_mod = model
    base_mod ||= controller
    base_mod ||= job

    return if base_mod.blank?

    available_modules = I18n.t('modules').keys

    parts = base_mod.split('/')
    (parts.length - 1).downto(1) do |i|
      mod = parts[0..i].join('/')
      return mod if available_modules.include?(mod.to_sym)
    end

    parts.first
  end

  def updated_field_names
    return self[:updated_field_names] if self[:updated_field_names]
    return [] if updated_fields.blank?
    updated_fields.map { |m| item ? item.t(m, default: m).presence : nil }.compact.uniq
  end

  private

  def set_string_data
    self.model_name ||= I18n.t("mongoid.models.#{model}") if model.present?
    self.job_name ||= I18n.t("job.models.#{job}") if job.present?
    self.updated_field_names = updated_field_names unless self[:updated_field_names]
  end
end
