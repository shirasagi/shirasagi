module Webmail::Addon
  module MailFile
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []
    end

    def save_files
    end

    def destroy_files
      files.destroy_all
    end
  end
end
