# coding: utf-8
class Opendata::Resource
  include SS::Document
  include SS::Relation::File

  seqid :id
  field :name, type: String
  field :text, type: String
  field :format, type: String

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :resource
  belongs_to_file :file

  permit_params :name, :text, :format

  validates :name, presence: true
  validates :format, presence: true

  public
    def filename
      file ? file.filename : nil
    end

    def content_type
      file ? file.content_type : nil
    end

    def size
      file ? file.length : nil
    end

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
