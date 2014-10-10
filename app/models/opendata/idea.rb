class Opendata::Idea
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::OwnerPermission
  include Opendata::Addon::Category
  include Opendata::Addon::Dataset
  include Opendata::Addon::App

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :point, type: Integer
  field :text, type: String
  field :tags, type: Array

  belongs_to :dataset, class_name: "Opendata::Dataset"
  belongs_to :app, class_name: "Opendata::App"

  permit_params :state, :name, :dataset_id, :app_id, :text, :point, tags: []

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  class << self
    def public
      where(state: "public")
    end
  end
end
