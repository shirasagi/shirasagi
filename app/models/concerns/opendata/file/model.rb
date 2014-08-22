# coding: utf-8
module Opendata::File::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  attr_accessor :in_file, :in_files

  included do
    store_in collection: "od_dataset_files"

    seqid :id
    field :model, type: String
    field :file_id, type: String
    field :state, type: String, default: "public"
    field :filename, type: String
    field :size, type: Integer
    field :content_type, type: String

    permit_params :state, :filename
    permit_params :in_file, :in_files, in_files: []

    before_validation :set_filename, if: ->{ in_file.present? }

    validates :model, presence: true
    validates :state, presence: true
    validates :filename, presence: true, if: ->{ !in_file && !in_files }

    before_save :save_file
    before_destroy :remove_file

  end

  class UploadedFile < ::Tempfile
    attr_accessor :original_filename, :content_type
  end

  public
    def state_options
      #[ %w[公開 public], %w[非公開 closed] ]
      [ %w[公開 public] ]
    end

    def name
      filename
    end

    def basename
      filename.to_s.sub(/.*\//, "")
    end

    def extname
      filename.to_s.sub(/.*\W/, "")
    end

    def image?
      filename =~ /\.(bmp|gif|jpe?g|png)$/i
    end

    def file
      file_id.blank? ? nil : Mongoid::GridFs.get(file_id) rescue nil
    end

    def read
      file.data
    end

    def save_files
      return false unless valid?

      in_files.each do |file|
        item = self.class.new(attributes)
        item.in_file = file
        next if item.save

        item.errors.full_messages.each {|m| errors.add :base, m }
        return false
      end
      true
    end

    def uploaded_file
      file = UploadedFile.new("aa")
      file.binmode
      file.write(read)
      file.original_filename = basename
      file.content_type = content_type
      file
    end

  private
    def set_filename
      self.filename   ||= in_file.original_filename
      self.size         = in_file.size
      self.content_type = in_file.content_type
    end

    def save_file
      errors.add :in_file, :blank if new_record? && in_file.blank?
      return false if errors.present?
      return if in_file.blank?

      if fs = file
        fs.delete
        fs = Mongoid::GridFs.put in_file, _id: file_id
      else
        fs = Mongoid::GridFs.put in_file
        self.file_id = fs.id
      end
    end

    def remove_file
      if file_id.present?
        Mongoid::GridFs.delete(file_id) rescue nil
      end
    end
end
