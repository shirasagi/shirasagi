class SS::Ldap::SearchDiagnostic
  extend SS::Translation
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_dn, :string
  attribute :user_password, :string
  attribute :base_dn, :string
  attribute :scope, :string, default: ->{ "whole_subtree" }
  attribute :filter, :string, default: ->{ "(objectclass=*)" }
  attribute :attrs, :string

  validates :user_dn, presence: true
  validates :base_dn, presence: true, ldap_dn: true
  validates :scope, inclusion: { in: %w(base_object single_level whole_subtree), allow_blank: true }
  validates :filter, presence: true, ldap_filter: true

  def scope_options
    %w(base_object single_level whole_subtree).map do |v|
      [ I18n.t("ldap.options.search_scope.#{v}"), v ]
    end
  end
end
