class Gws::Ldap::SyncTask
  include Gws::Model::Task
  include Gws::SitePermission

  TASK_NAME = "gws:ldap::sync_task".freeze

  set_permission_name "gws_groups", :edit

  default_scope ->{ where(name: Gws::Ldap::SyncTask::TASK_NAME) }

  field :admin_dn, type: String
  field :admin_password, type: String
  field :group_base_dn, type: String
  field :group_scope, type: String
  field :group_filter, type: String
  field :group_root_dn, type: String
  field :user_base_dn, type: String
  field :user_scope, type: String
  field :user_filter, type: String
  embeds_ids :user_roles, class_name: "Gws::Role"

  attr_accessor :in_admin_password

  permit_params :admin_dn, :in_admin_password
  permit_params :group_base_dn, :group_scope, :group_filter, :group_root_dn
  permit_params :user_base_dn, :user_scope, :user_filter, user_role_ids: []

  before_validation :set_admin_password

  validates :group_base_dn, ldap_dn: true
  validates :group_scope, inclusion: { in: %w(base_object single_level whole_subtree), allow_blank: true }
  validates :group_filter, ldap_filter: true
  validates :group_root_dn, ldap_dn: true
  validates :user_base_dn, ldap_dn: true
  validates :user_scope, inclusion: { in: %w(base_object single_level whole_subtree), allow_blank: true }
  validates :user_filter, ldap_filter: true

  def group_scope_options
    %w(base_object single_level whole_subtree).map do |v|
      [ I18n.t("ldap.options.search_scope.#{v}"), v ]
    end
  end
  alias user_scope_options group_scope_options

  private

  def set_admin_password
    return if in_admin_password.blank?
    self.admin_password = SS::Crypto.encrypt(in_admin_password)
  end
end
