# coding: utf-8
class Opendata::Resource
  include SS::Document
  include SS::Relation::File

  seqid :id
  field :name, type: String
  field :filename, type: String
  field :text, type: String
  field :format, type: String

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :resource
  belongs_to_file :file

  permit_params :name, :text, :format

  validates :name, presence: true
  validates :format, presence: true

  before_validation :set_filename, if: ->{ in_file.present? }
  before_save :save_static_file, if: ->{ in_file.present? }
  before_save :save_fuseki_rdf, if: ->{ in_file.present? && format.upcase == "TTL" }
  before_destroy :remove_static_file
  before_destroy :remove_fuseki_rdf

  public
    def path
      dataset.path.sub(/\/[^\/]+$/, "/resource/#{id}/#{filename}")
    end

    def url
      dataset.url.sub(/\/[^\/]+$/, "/resource/#{id}/#{filename}")
    end

    def full_url
      dataset.full_url.sub(/\/[^\/]+$/, "/resource/#{id}/#{filename}")
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

  private
    def set_filename
      self.filename = in_file.original_filename
      self.format = filename.sub(/.*\./, "").upcase if format.blank?
    end

    def save_static_file
      Fs.rm_rf File.dirname(path)
      Fs.binwrite path, file.data
    end

    def remove_static_file
      Fs.rm_rf path
    end

    def save_fuseki_rdf
      Rdf::Sparql.save full_url, path
    end

    def remove_fuseki_rdf
      Rdf::Sparql.clear full_url
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
