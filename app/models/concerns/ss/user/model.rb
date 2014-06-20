# coding: utf-8
module SS::User::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  
  attr_accessor :in_password
  
  included do
    store_in collection: "ss_users"
    index({ email: 1 }, { unique: true })
    
    seqid :id
    field :name, type: String
    field :email, type: String, metadata: { form: :email }
    field :password, type: String
    embeds_ids :groups, class_name: "SS::Group"
    
    permit_params :name, :email, :password, :in_password, group_ids: []
    
    validates :name, presence: true, length: { maximum: 40 }
    validates :email, uniqueness: true, presence: true, email: true, length: { maximum: 80 }
    validates :password, presence: true
    
    before_validation :encrypt_password, if: ->{ in_password.present? }
  end
  
  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
  end
end
