module Cms::Lgwan
  module File
    extend ActiveSupport::Concern
    include Cms::Lgwan::Base

    included do
      delegate_lgwan_in_web :generate_public_file
      delegate_lgwan_in_web :remove_public_file
    end

    def generate_public_file_in_web
    end

    def remove_public_file_in_web
      dir = public_dir
      return if dir.blank?
      dir = dir.delete_prefix("#{Rails.root}/")
      Uploader::JobFile.new_job(site_id: site.id).bind_rm([dir]).save_job
    end
  end
end
