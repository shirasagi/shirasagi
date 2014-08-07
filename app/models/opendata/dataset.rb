# coding: utf-8
class Opendata::Dataset
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :site_id, type: Integer
  field :user_id, type: Integer
  field :group_id, type: Integer
  embeds_ids :categry_ids, class_name: "Cms::Node"
  field :point, type: Integer, default: "0"
  field :text, type: String
  field :license, type: String

  permit_params :state, :name, :categry_ids, :point, :text, :license

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
