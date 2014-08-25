# coding: utf-8
class Opendata::DataGroup
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::OwnerPermission
  include Opendata::Addon::Category

  set_permission_name :opendata_datasets

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :order, type: Integer

  permit_params :state, :name, :order, file_ids: []

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  class << self
    def public
      where(state: "public")
    end
  end
end
