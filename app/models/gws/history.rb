class Gws::History
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site

  seqid :id
  field :name, type: String
  field :mode, type: String, default: 'create'
  field :model, type: String
  field :item_id, type: String
  field :updated_fields, type: Array

  validates :name, presence: true
  validates :mode, presence: true
  validates :model, presence: true
  validates :item_id, presence: true

  default_scope -> {
    order_by created: -1
  }

  def mode_name
    I18n.t("gws.history.mode.#{mode}")
  end

  def item
    @item ||= model.camelize.constantize.where(id: item_id).first
  end

  def updated_field_names
    return [] if updated_fields.blank?
    updated_fields.map { |m| item.t(m) }
  end
end
