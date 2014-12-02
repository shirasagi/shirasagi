class Opendata::Resource
  include SS::Document
  include SS::Relation::File
  include Opendata::Addon::RdfStore

  seqid :id
  field :name, type: String
  field :filename, type: String
  field :text, type: String
  field :format, type: String

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :resource
  belongs_to :license, class_name: "Opendata::License"
  belongs_to_file :file
  belongs_to_file :tsv

  permit_params :name, :text, :format, :license_id

  validates :name, presence: true
  validates :format, presence: true
  validates :license, presence: true

  before_validation :set_filename, if: ->{ in_file.present? }
  before_validation :set_format

  after_save -> { dataset.save(validate: false) }
  after_destroy -> { dataset.save(validate: false) }

  public
    def url
      dataset.full_url.sub(/\.html$/, "") + "/resource/#{id}/#{filename}"
    end

    def full_url
      dataset.full_url.sub(/\.html$/, "") + "/resource/#{id}/#{filename}"
    end

    def content_url
      dataset.full_url.sub(/\.html$/, "") + "/resource/#{id}/content.html"
    end

    def path
      file ? file.path : nil
    end

    def content_type
      file ? file.content_type : nil
    end

    def size
      file ? file.size : nil
    end

    def tsv_present?
      if tsv || %(CSV TSV).index(format)
        true
      end
    end

    def parse_tsv
      require "nkf"
      require "csv"

      src  = tsv || file
      data = NKF.nkf("-w", src.read)
      sep  = data =~ /\t/ ? "\t" : ","
      CSV.parse(data, col_sep: sep) rescue nil
    end

    def allowed?(action, user, opts = {})
      true
    end

  private
    def set_filename
      self.filename = in_file.original_filename
      self.format = filename.sub(/.*\./, "").upcase if format.blank?
    end

    def set_format
      self.format = format.upcase if format.present?
    end

  class << self
    public
      def allowed?(action, user, opts = {})
        true
      end

      def allow(action, user, opts = {})
        true
      end

      def format_options
        %w(AVI BMP CSV DOC DOCX DOT GIF HTML JPG LZH MOV MP3 MPG ODS
           ODT OTS OTT RAR RTF RDF TAR TGZ TTL TXT WAV XLS XLT XLSX XML ZIP)
      end


      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        criteria = criteria.where(name: /#{params[:keyword]}/) if params[:keyword].present?
        criteria
      end
  end
end
