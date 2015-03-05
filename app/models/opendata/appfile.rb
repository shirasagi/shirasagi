class Opendata::Appfile
  include SS::Document
  include SS::Relation::File

  seqid :id
  field :filename, type: String
  field :text, type: String
  field :format, type: String

  embedded_in :app, class_name: "Opendata::App", inverse_of: :appfile
  belongs_to_file :file

  permit_params :text

  validates :in_file, presence: true, if: ->{ file_id.blank? }
  validates :filename, uniqueness: true

  before_validation :set_filename, if: ->{ in_file.present? }

  after_save -> { app.save(validate: false) }
  after_destroy -> { app.save(validate: false) }

  public
    def url
      app.url.sub(/\.html$/, "") + "/appfile/#{id}/#{filename}"
    end

    def full_url
      app.full_url.sub(/\.html$/, "") + "/appfile/#{id}/#{filename}"
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

      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        criteria = criteria.where(filename: /#{params[:keyword]}/) if params[:keyword].present?

        criteria
      end
  end
end
