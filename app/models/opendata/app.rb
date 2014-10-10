class Opendata::App
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::OwnerPermission
  include Opendata::Addon::Category
  include Opendata::Addon::Dataset

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :point, type: Integer
  field :text, type: String
  field :license, type: String
  field :tags, type: Array
  field :excuted, type: Integer

  embeds_ids :datasets, class_name: "Opendata::Dataset"

  permit_params :state, :name, :text, :license, :dataset_ids, tags: []

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  class << self
    def public
      where(state: "public")
    end
  end
end
