# coding: utf-8
class Opendata::Dataset
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::OwnerPermission
  include Opendata::Addon::Category
  include Opendata::Addon::DataGroup
  include Opendata::Addon::Area

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :point, type: Integer, default: "0"
  field :text, type: String
  field :license, type: String
  field :url, type: String
  field :downloaded, type: Integer

  embeds_ids :categories, class_name: "Cms::Node"
  embeds_ids :files, class_name: "Opendata::DatasetFile"

  permit_params file_ids: []
  permit_params :state, :name, :text, :license, :url

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  class << self
    def public
      where(state: "public")
    end
  end
end
