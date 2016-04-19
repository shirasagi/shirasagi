class Gws::Reminder
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::UserPermission

  seqid :id
  field :name, type: String
  field :model, type: String
  field :date, type: DateTime
  field :item_id, type: String
  field :read_at, type: DateTime
  field :updated_fields, type: Array
  field :updated_user_id, type: Integer
  field :updated_user_uid, type: String
  field :updated_user_name, type: String

  permit_params :name, :model, :date, :item_id

  validates :name, presence: true
  validates :model, presence: true
  validates :date, datetime: true
  validates :item_id, presence: true

  default_scope -> {
    order_by date: 1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }

  def item
    @item ||= model.camelize.constantize.where(id: item_id).first
  end

  def url_lazy
    return -> { '#' } unless item
    url, options = item.reminder_url
    -> { send url, options }
  end

  def updated?
    updated_fields.present?
  end

  def unread?
    read_at.to_i < updated.to_i
  end

  def updated_field_names
    return [] if updated_fields.blank?
    updated_fields.map { |m| item.t(m) }
  end
end
