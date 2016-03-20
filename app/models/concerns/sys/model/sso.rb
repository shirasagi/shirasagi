module Sys::Model::SSO
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    store_in collection: "ss_sso"
    index({ name: 1 }, { unique: true })

    seqid :id
    field :name, type: String
    field :filename, type: String
    field :text, type: String
    field :order, type: Integer, default: 0
    field :state, type: String, default: 'enabled'
    field :route, type: String
    permit_params :name, :filename, :text, :order, :state

    before_validation :set_route
    validates :name, presence: true, uniqueness: true, length: { maximum: 80 }
    validates :filename, presence: true, uniqueness: true, length: { maximum: 200 }, format: { with: /\A[\w\-_]+\z/ }
    validates :state, presence: true, inclusion: { in: %w(enabled disabled) }
  end

  def becomes_with_route(name = nil)
    name ||= route
    return self unless name
    klass = name.camelize.constantize rescue nil
    return self unless klass

    item = klass.new
    item.instance_variable_set(:@new_record, nil) unless new_record?
    instance_variables.each {|k| item.instance_variable_set k, instance_variable_get(k) }
    item
  end

  def state_options
    %w(enabled disabled).map { |v| [I18n.t("sys.options.sso_state.#{v}"), v] }
  end

  def url
    ".#{route}/#{filename}/init"
  end

  private

  def set_route
    self.route ||= self.class.to_s.underscore
  end
end
