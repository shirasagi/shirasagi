module Cms::Lgwan
  module Node
    extend ActiveSupport::Concern
    include Cms::Lgwan::Base

    included do
      delegate_lgwan_in_web :rename_children_files
      delegate_lgwan_in_web :remove_owned_files
      delegate_lgwan_in_web :remove_all
    end

    def rename_children_files_in_web(src, dst)
      Uploader::JobFile.new_job(site_id: site.id).bind_rm([src]).save_job
    end

    def remove_owned_files_in_web
      return if !Dir.exist?(path)

      fullnames = []
      Dir.foreach(path) do |name|
        next if name == '.' || name == '..'

        fullname = "#{path}/#{name}"
        next if ::File::ftype(fullname) != 'file'
        fullnames << fullname
      end

      return if fullnames.blank?
      fullnames = fullnames.map { |fullname| fullname.delete_prefix("#{Rails.root}/") }
      Uploader::JobFile.new_job(site_id: site.id).bind_rm(fullnames).save_job
    end

    def remove_all_in_web
      src = path.delete_prefix("#{Rails.root}/")
      Uploader::JobFile.new_job(site_id: site.id).bind_rm([src]).save_job
    end
  end
end
