module Cms
  PreviewLink = Data.define(:internal, :expanded) do
    def internal?
      internal
    end

    def external?
      !internal?
    end

    class << self
      def parse(site, preview_base, preview_path, url)
        preview_path = preview_path.to_s

        full_url = Addressable::URI.parse(url)
        if full_url.scheme && full_url.scheme != "http" && full_url.scheme != "https"
          return new(internal: true, expanded: url)
        end

        if full_url.host.blank?
          from_path(site, preview_base, preview_path, url)
        else
          from_host(site, preview_base, preview_path, url)
        end
      end

      private

      def from_host(site, preview_base, preview_path, url)
        if url.start_with?(site.full_url) || (url + "/") == site.full_url
          full_root_url = site.full_root_url.delete_suffix("/")
          path = url.delete_prefix(full_root_url)
          path = "/" + path if path[0] != "/"
          internal = cur_site_path?(site, path)
          expanded = internal ? (preview_base + path) : url
          new(internal: internal, expanded: expanded)
        else
          new(internal: false, expanded: url)
        end
      end

      def from_path(site, preview_base, preview_path, url)
        # assets
        if url.start_with?("/assets/", "/assets-dev/")
          return new(internal: true, expanded: url)
        end

        # #
        if url[0] == "#"
          return new(internal: true, expanded: url)
        end

        # / ./ ../ index.html
        if preview_path.end_with?(".html")
          dir = ::File.dirname(site.url + preview_path)
        else
          dir = site.url + preview_path
        end
        path = Pathname(dir).join(url).to_s
        internal = cur_site_path?(site, path)
        expanded = internal ? (preview_base + path) : url
        new(internal: internal, expanded: expanded)
      end

      def cur_site_path?(site, path)
        # /fs/
        if path.start_with?("/fs/")
          return true
        end

        same_site = site.same_domain_site_from_path(path)
        same_site && (same_site.id == site.id)
      end
    end
  end
end
