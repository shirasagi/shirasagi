# coding: utf-8
class Opendata::App
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site

  seqid :id
  field :state, type: String, default: "public"
  field :site_id, type: Integer
  field :name, type: String
  field :user_id, type: Integer
  field :group_id, type: Integer
  embeds_ids :categry_ids, class_name: "Cms::Node"
  embeds_ids :dataset_ids, class_name: "Cms::Node"
  field :point, type: Integer
  field :text, type: String
  field :license, type: String

  permit_params :state, :name, :categry_ids, :dataset_ids, :text, :license

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  public
    # dummy
    def allowed?(premit)
      true
    end

  class << self
    public
      # def
  end
end
