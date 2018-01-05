module SS::Model::Address
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    field :name, type: String
    field :kana, type: String
    field :company, type: String
    field :title, type: String
    field :tel, type: String
    field :email, type: String

    field :home_postal_code, type: String
    field :home_prefecture, type: String
    field :home_city, type: String
    field :home_street_address, type: String
    field :home_tel, type: String
    field :home_fax, type: String

    field :office_postal_code, type: String
    field :office_prefecture, type: String
    field :office_city, type: String
    field :office_street_address, type: String
    field :office_tel, type: String
    field :office_fax, type: String

    field :personal_webpage, type: String
    field :memo, type: String

    belongs_to :member, class_name: "Gws::User"

    permit_params :member_id, :name, :kana, :company, :title, :tel, :email,
                  :home_postal_code, :home_prefecture, :home_city, :home_street_address, :home_tel, :home_fax,
                  :office_postal_code, :office_prefecture, :office_city, :office_street_address, :office_tel, :office_fax,
                  :personal_webpage, :memo

    validates :name, presence: true
    validates :email, email: true

    default_scope ->{ order_by kana: 1, name: 1 }

    scope :and_has_email, ->{ where :email.exists => true }
    scope :and_has_member, ->{ where :member_id.exists => true }
  end

  def email_address
    return nil if email.blank?
    %(#{name} <#{email}>)
  end
end
