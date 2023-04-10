module Cms::Lgwan
  module Page
    extend ActiveSupport::Concern
    include Cms::Lgwan::Base

    included do
      delegate_lgwan_in_web :generate_file
      delegate_lgwan_in_web :rename_file
      delegate_lgwan_in_web :remove_file

      # after_remove_file
      if include?(Sitemap::Addon::Body)
        delegate_lgwan_in_web :rename_sitemap_xml
        delegate_lgwan_in_web :remove_sitemap_xml
      end
    end

    def generate_file_in_web(opts = {})
      return false unless serve_static_file?
      return false unless public?
      return false unless public_node?
      return false if (@cur_site || site).generate_locked?

      # do not run_callbacks :generate_file
      # only call job if it's necessary

      # elastic search
      if opts[:release] != false
        Cms::PageRelease.release(self)
      end

      # opendata
      if respond_to?(:invoke_opendata_job)
        invoke_opendata_job(:create_or_update)
      end

      0
    end

    def rename_file_in_web
      filename_changes = changes['filename'].presence || previous_changes['filename']
      return unless filename_changes
      return unless filename_changes[0]

      src = "#{site.path}/#{filename_changes[0]}"
      src = src.delete_prefix("#{Rails.root}/")
      run_callbacks :rename_file do
        Uploader::JobFile.new_job(site_id: site.id).bind_rm([src]).save_job
        Cms::PageRelease.close(self, filename_changes[0])
      end
    end

    def remove_file_in_web
      src = "#{site.path}/#{filename}"
      src = src.delete_prefix("#{Rails.root}/")
      run_callbacks :remove_file do
        Uploader::JobFile.new_job(site_id: site.id).bind_rm([src]).save_job
        Cms::PageRelease.close(self)
      end
    end

    # after_remove_file
    def remove_sitemap_xml_in_web
      file = sitemap_xml_path
      file = file.delete_prefix("#{Rails.root}/")
      Uploader::JobFile.new_job(site_id: site.id).bind_rm([file]).save_job
    end

    def rename_sitemap_xml_in_web
      filename_changes = changes['filename'].presence || previous_changes['filename']
      src = "#{site.path}/#{filename_changes[0]}"
      src = src.sub(/\.[^\/]+$/, ".xml")
      src = src.delete_prefix("#{Rails.root}/")
      Uploader::JobFile.new_job(site_id: site.id).bind_rm([src]).save_job
    end
  end
end
