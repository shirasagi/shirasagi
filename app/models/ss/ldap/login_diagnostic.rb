class SS::Ldap::LoginDiagnostic
  extend SS::Translation
  include ActiveModel::Model
  include ActiveModel::Attributes

  # dn can be DN but also email address
  attribute :dn, :string
  attribute :password, :string

  validates :dn, presence: true
  validates :password, presence: true
end
