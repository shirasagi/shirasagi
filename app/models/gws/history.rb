class Gws::History
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  seqid :id
  field :session_id, type: String
  field :request_id, type: String
  field :severity, type: String, default: 'error'
  field :name, type: String
  field :mode, type: String, default: 'create'
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

  with_options on: :model do |validation|
    validation.validates :name, presence: true
    validation.validates :mode, presence: true
    validation.validates :model, presence: true
    validation.validates :item_id, presence: true
  end
  with_options on: :controller do |validation|
    validation.validates :controller, presence: true
    validation.validates :path, presence: true
    validation.validates :action, presence: true
    validation.validates :message, presence: true
  end
  with_options on: :job do |validation|
    validation.validates :job, presence: true
    validation.validates :action, presence: true
    validation.validates :message, presence: true
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
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :session_id, :request_id, :name, :model_name, :user_name, :user_group_name)
    end

    def error!(context, cur_user, cur_site, attributes)
      write!(:error, context, cur_user, cur_site, attributes)
    end

    def warn!(context, cur_user, cur_site, attributes)
      write!(:warn, context, cur_user, cur_site, attributes)
    end

    def info!(context, cur_user, cur_site, attributes)
      write!(:info, context, cur_user, cur_site, attributes)
    end

    def notice!(context, cur_user, cur_site, attributes)
      write!(:notice, context, cur_user, cur_site, attributes)
    end

    def write!(severity, context, cur_user, cur_site, attributes)
      item = new(
        cur_user: cur_user,
        cur_site: cur_site,
        session_id: Rails.application.current_session_id,
        request_id: Rails.application.current_request_id,
        severity: severity
      )
      item.attributes = attributes

      if allowed_severity = cur_site.allowed_log_severity_for(item.module_key)
        if severity_to_num(severity) >= severity_to_num(allowed_severity)
          item.save!(context: context.to_sym)
        end
      end
    end

    private

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
      I18n.t("gws.history.mode.#{mode}")
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
    updated_fields.map { |m| item ? item.t(m, default: '').presence : nil }.compact.uniq
  end

  private

  def set_string_data
    self.model_name ||= I18n.t("mongoid.models.#{model}") if model.present?
    self.job_name ||= I18n.t("job.models.#{job}") if job.present?
    self.updated_field_names = updated_field_names unless self[:updated_field_names]
  end

  class << self
    def updated?
      where(mode: 'update').exists?
    end
  end
end
