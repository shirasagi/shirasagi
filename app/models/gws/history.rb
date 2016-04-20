class Gws::History
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  seqid :id
  field :name, type: String
  field :mode, type: String, default: 'create'
  field :model, type: String
  field :model_name, type: String
  field :item_id, type: String
  field :updated_fields, type: Array
  field :updated_field_names, type: Array

  validates :name, presence: true
  validates :mode, presence: true
  validates :model, presence: true
  validates :item_id, presence: true

  before_save :set_string_data

  default_scope -> {
    order_by created: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :model_name, :user_name, :user_group_name
    end
    criteria
  }

  def model_name
    self[:model_name] || I18n.t("mongoid.models.#{model}")
  end

  def mode_name
    I18n.t("gws.history.mode.#{mode}")
  end

  def item
    @item ||= model.camelize.constantize.where(id: item_id).first
  end

  def updated_field_names
    return self[:updated_field_names] if self[:updated_field_names]
    return [] if updated_fields.blank?
    updated_fields.map { |m| item ? item.t(m, default: '').presence : nil }.compact.uniq
  end

  private
    def set_string_data
      self.model_name = model_name unless self[:model_name]
      self.updated_field_names = updated_field_names unless self[:updated_field_names]
    end

  class << self
    def updated?
      where(mode: 'update').exists?
    end
  end
end
