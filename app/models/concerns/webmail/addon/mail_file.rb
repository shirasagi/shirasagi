module Webmail::Addon
  module MailFile
    extend ActiveSupport::Concern
    extend SS::Addon

    attr_accessor :ref_file_ids, :ref_file_uid

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params :ref_file_uid, file_ids: [], ref_file_ids: []
    end

    def set_ref_files(parts)
      @ref_file_parts = parts
    end

    def ref_files
      @ref_file_parts || []
    end

    def ref_files_with_data
      return [] if ref_file_ids.blank? || ref_file_uid.blank?
      file_ids = ref_file_ids.map { |c| c.sub(/^ref-/, '') }

      file_ids.map do |section|
        part = imap.mails.find_part ref_file_uid, section
        OpenStruct.new(
          name: part.filename,
          read: part.decoded
        )
      end
    end

    def save_files
    end

    def destroy_files
      files.destroy_all
    end
  end
end
