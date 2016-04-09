module Sys::Model::Auth
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    store_in collection: "ss_auths"
    index({ name: 1 }, { unique: true })

    seqid :id
    field :model, type: String
    field :name, type: String
    field :filename, type: String
    field :text, type: String
    field :order, type: Integer, default: 0
    field :state, type: String, default: 'enabled'
    permit_params :name, :filename, :text, :order, :state

    validates :name, presence: true, uniqueness: true, length: { maximum: 80 }
    validates :filename, presence: true, uniqueness: true, length: { maximum: 200 }, format: { with: /\A[\w\-_]+\z/ }
    validates :state, presence: true, inclusion: { in: %w(enabled disabled) }
  end

  def becomes_with_model(name = nil)
    name ||= model
    return self unless name
    klass = name.camelize.constantize rescue nil
    return self unless klass

    item = klass.new
    item.instance_variable_set(:@new_record, nil) unless new_record?
    instance_variables.each {|k| item.instance_variable_set k, instance_variable_get(k) }
    item
  end

  def state_options
    %w(enabled disabled).map { |v| [I18n.t("sys.options.auth_state.#{v}"), v] }
  end

  def url
    raise NotImplementedError
  end
end
