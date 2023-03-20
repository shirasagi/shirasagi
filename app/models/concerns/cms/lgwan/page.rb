module Cms::Lgwan
  module Page
    extend ActiveSupport::Concern
    include Cms::Lgwan::Base

    included do
      delegate_lgwan_inweb :generate_file
      delegate_lgwan_inweb :rename_file
      delegate_lgwan_inweb :remove_file

      # after_remove_file
      if include?(Sitemap::Addon::Body)
        delegate_lgwan_inweb :rename_sitemap_xml
        delegate_lgwan_inweb :remove_sitemap_xml
      end
    end

    def generate_file_in_inweb(opts = {})
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

    def rename_file_in_inweb
      return unless @db_changes["filename"]
      return unless @db_changes["filename"][0]

      src = "#{site.path}/#{@db_changes['filename'][0]}"
      src = src.delete_prefix("#{Rails.root}/")
      run_callbacks :rename_file do
        Uploader::JobFile.new_job(site_id: site.id).bind_rm([src]).save_job
        Cms::PageRelease.close(self, @db_changes['filename'][0])
      end
    end

    def remove_file_in_inweb
      src = "#{site.path}/#{filename}"
      src = src.delete_prefix("#{Rails.root}/")
      run_callbacks :remove_file do
        Uploader::JobFile.new_job(site_id: site.id).bind_rm([src]).save_job
        Cms::PageRelease.close(self)
      end
    end

    # after_remove_file
    def remove_sitemap_xml_in_inweb
      file = sitemap_xml_path
      file = file.delete_prefix("#{Rails.root}/")
      Uploader::JobFile.new_job(site_id: site.id).bind_rm([file]).save_job
    end

    def rename_sitemap_xml_in_inweb
      src = "#{site.path}/#{@db_changes['filename'][0]}"
      src = src.sub(/\.[^\/]+$/, ".xml")
      src = src.delete_prefix("#{Rails.root}/")
      Uploader::JobFile.new_job(site_id: site.id).bind_rm([src]).save_job
    end
  end
end
