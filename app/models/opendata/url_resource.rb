class Opendata::UrlResource
  include SS::Document
  include SS::Relation::File
  include Opendata::Addon::RdfStore

  seqid :id
  field :name, type: String
  field :filename, type: String
  field :text, type: String
  field :format, type: String
  field :original_url, type: String

  field :original_updated, type: DateTime
  field :crawl_state, type: String, default: "same"

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :url_resource
  belongs_to :license, class_name: "Opendata::License"
  belongs_to_file :file
  belongs_to_file :tsv

  permit_params :name, :text, :license_id, :original_url

  validates :name, presence: true
  validates :license_id, presence: true

  validate :validate_original_url

  after_save -> { dataset.save(validate: false) }
  after_destroy -> { dataset.save(validate: false) }

  public
    def url
      dataset.url.sub(/\.html$/, "") + "/url_resource/#{id}/#{filename}"
    end

    def full_url
      dataset.full_url.sub(/\.html$/, "") + "/url_resource/#{id}/#{filename}"
    end

    def content_url
      dataset.full_url.sub(/\.html$/, "") + "/url_resource/#{id}/content.html"
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
      if format.blank?
        true if tsv
      else
        true if tsv || %(CSV TSV).index(format.upcase)
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

    def validate_original_url

      require 'net/http'
      require "open-uri"
      require "resolv-replace"
      require 'timeout'

      uri = URI.parse(original_url)

      if uri.path == '/'
        errors.add :original_url, :invalid
        return
      end

      begin

        http = Net::HTTP.new(uri.host)
        http.open_timeout = 10
        http.read_timeout = 30
        response = http.start do |http|
          http.head(uri.path)
        end

        unless response = Net::HTTPSuccess
          errors.add :original_url, :invalid
          return
        end

      rescue => e
        errors.add :original_url, :invalid
        return

      end

      begin
        time_out = 30
        timeout(time_out){

          self.original_updated = open(original_url).last_modified
          if self.original_updated.blank?
            errors.add :base, I18n.t("opendata.errors.messages.dynamic_file")
            return
          end

          self.filename = File.basename(uri.path)
          temp_file = Tempfile.new("temp")

          File.open(temp_file , 'wb') do |output|
            open(original_url) do |data|
              output.write(data.read)
            end
          end

          in_file = temp_file
          (class << in_file; self; end).class_eval do
            define_method(:original_filename) { File.basename(uri.path) }
            define_method(:filename) { File.basename(uri.path) }
            define_method(:content_type) { 'application/octet-stream' }
          end

          ss_file = SS::File.new
          ss_file.in_file = in_file
          ss_file.model = self.class.to_s.underscore

          ss_file.content_type = self.format = original_url.sub(/.*\./, "").downcase #"csv"
          ss_file.filename = File.basename(uri.path)
          ss_file.save
          send("file_id=", ss_file.id)

          in_file.close

          }

      rescue TimeoutError
        errors.add :base, I18n.t("opendata.errors.messages.invalid_timeout")
        return

      rescue
        errors.add :original_url, :invalid
        return

      end
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
        criteria = criteria.where(format: params[:format].upcase) if params[:format].present?

        criteria
      end
  end
end

