module Sitemap::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :sitemap_urls, type: SS::Extensions::Lines
      field :sitemap_depth, type: Integer, default: 3
      field :sitemap_page_state, type: String, default: "hide"
      field :sitemap_deny_urls, type: SS::Extensions::Lines
      permit_params :sitemap_urls, :sitemap_depth, :sitemap_page_state, :sitemap_deny_urls

      after_generate_file :generate_sitemap_xml
      after_remove_file :remove_sitemap_xml
      after_rename_file :rename_sitemap_xml
    end

    def sitemap_xml_path
      path.sub(/\.[^\/]+$/, ".xml")
    end

    def sitemap_depth
      value = self[:sitemap_depth].to_i
      (value < 1 || 5 < value) ? 5 : value
    end

    def sitemap_page_state_options
      [
        [I18n.t('ss.options.state.show'), 'show'],
        [I18n.t('ss.options.state.hide'), 'hide'],
      ]
    end

    private

    def generate_sitemap_xml
      file = sitemap_xml_path
      service = Sitemap::RenderService.new(cur_site: @cur_site || self.site, cur_node: @cur_node || self.parent, page: self)
      data = service.render_xml
      return if Fs.exist?(file) && data == Fs.read(file)
      Fs.write file, data
    end

    def remove_sitemap_xml
      file = sitemap_xml_path
      Fs.rm_rf(file) if Fs.file?(file)
    end

    def rename_sitemap_xml
      filename_changes = changes['filename'].presence || previous_changes['filename']
      src = "#{site.path}/#{filename_changes[0]}"
      dst = "#{site.path}/#{filename_changes[1]}"

      src = src.sub(/\.[^\/]+$/, ".xml")
      dst = dst.sub(/\.[^\/]+$/, ".xml")
      Fs.mv src, dst if Fs.exist?(src)
    end
  end
end
