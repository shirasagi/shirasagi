class Opendata::Appfile
  include SS::Document
  include SS::Relation::File
  include Opendata::TsvParseable
  include Opendata::AllowableAny
  include Opendata::Common

  seqid :id
  field :filename, type: String
  field :text, type: String
  field :format, type: String

  embedded_in :app, class_name: "Opendata::App", inverse_of: :appfile
  belongs_to_file :file

  permit_params :text

  validates :in_file, presence: true, if: ->{ file_id.blank? }
  validates :filename, uniqueness: true
  validate :validate_appfile

  before_validation :set_filename, if: ->{ in_file.present? }

  after_save -> { app.save(validate: false) }
  after_destroy -> { app.save(validate: false) }

  public
    def url
      get_url(url, "/appfile/#{id}/#{filename}")
    end

    def content_url
      get_url(url, "/appfile/#{id}/content.html")
    end

    def json_url
      get_url(url, "/appfile/#{id}/json.html")
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

  private
    def set_filename
      self.filename = in_file.original_filename
      self.format = filename.sub(/.*\./, "").upcase if format.blank?
    end

    def set_format
      self.format = format.upcase if format.present?
    end

    def validate_appfile
      if self.app.appurl.present?
        errors.clear
        errors.add :file_id, "はアプリの公開URLを登録している場合、登録できません。"
        return
      end
    end

  class << self
    public
      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        criteria = criteria.where(filename: /#{params[:keyword]}/) if params[:keyword].present?

        criteria
      end
  end
end
