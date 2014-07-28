# coding: utf-8
class History::Log
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site

  field :url, type: String
  field :controller, type: String
  field :action, type: String
  field :item_id, type: String
  field :item_class, type: String

  #permit_params :controller, :action, :item_id, :item_class

  validates :url, presence: true
  validates :controller, presence: true
  validates :action, presence: true
end
