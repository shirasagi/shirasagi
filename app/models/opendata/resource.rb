# coding: utf-8
class Opendata::Resource
  include SS::Document
  include SS::Relation::File

  seqid :id
  #field :file_id, type:
  field :name, type: String
  field :text, type: String
  field :format, type: String

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :resource
  belongs_to_file :file, class: "Opendata::ResourceFile"

  permit_params :name, :text, :format

  validates :name, presence: true
  validates :format, presence: true

  public
    def allowed?(action, user, opts = {})
      true
    end

  class << self
    public
      def allowed?(action, user, opts = {})
        true
      end

      def allow(action, user, opts = {})
        true
      end
  end
end
