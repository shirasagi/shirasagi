class SS::OAuth2::Application::Base
  include SS::Document
  include SS::Addon::OAuth2::SysPermission
  include SS::Addon::OAuth2::CmsPermission
  include SS::Addon::OAuth2::GwsPermission
  include SS::Addon::OAuth2::WebmailPermission
  include Sys::Permission

  store_in collection: 'ss_oauth2_applications'
  set_permission_name "sys_users", :edit

  field :name, type: String
  field :permissions, type: SS::Extensions::Words
  field :state, type: String
  field :client_id, type: String

  before_validation :normalize_permissions

  validates :name, presence: true, uniqueness: true
  validates :permissions, presence: true
  validates :state, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }
  validates :client_id, presence: true, uniqueness: true

  permit_params :name, :state, :client_id, permissions: []

  class << self
    def and_enabled
      all.where(state: "enabled")
    end
  end

  def state_options
    %w(enabled disabled).map do |value|
      [ I18n.t("ss.options.state.#{value}"), value ]
    end
  end

  private

  def normalize_permissions
    return if permissions.blank?

    self.permissions = permissions.map(&:strip).select(&:present?)
  end
end
