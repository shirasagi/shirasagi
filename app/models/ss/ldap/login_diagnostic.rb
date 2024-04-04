class SS::Ldap::LoginDiagnostic
  extend SS::Translation
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :dn, :string
  attribute :password, :string

  validates :dn, presence: true, ldap_dn: true
  validates :password, presence: true
end
