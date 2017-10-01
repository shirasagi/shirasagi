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
    field :memo, type: String

    permit_params :name, :kana, :company, :title, :tel, :email, :memo

    validates :name, presence: true
    validates :email, email: true

    default_scope ->{ order_by kana: 1, name: 1 }

    scope :and_has_email, ->{ where :email.exists => true }
  end

  def email_address
    return nil if email.blank?
    %(#{name} <#{email}>)
  end
end
