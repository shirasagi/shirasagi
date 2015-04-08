module Sitemap::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

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

    public
      def sitemap_xml_path
        path.sub(/\.[^\/]+$/, ".xml")
      end

      def sitemap_depth
        value = self[:sitemap_depth].to_i
        (value < 1 || 5 < value) ? 5 : value
      end

      def sitemap_page_state_options
        [%w(表示 show), %w(非表示 hide)]
      end

      def load_sitemap_urls(opts = {})
        urls = Cms::Node.where(site_id: site_id).public.
          where(:depth.lte => sitemap_depth).
          map { |m| opts[:name] ? "#{m.url} ##{m.name}" : m.url }

        if sitemap_page_state != "hide"
          urls += Cms::Page.where(site_id: site_id).public.
            where(:depth.lte => sitemap_depth).
            not(filename: /\/index\.html$/).
            map { |m| opts[:name] ? "#{m.url} ##{m.name}" : m.url }
        end

        # deny
        if sitemap_deny_urls.present?
          regex = sitemap_deny_urls.map { |m| /^\/?#{m}/ }
          regex = Regexp.union(regex)
          urls  = urls.reject { |url| url =~ regex }
        end

        urls.sort
      end

      def sitemap_list
        list = []
        urls = sitemap_urls.presence || load_sitemap_urls(name: true)
        urls.each do |url|
          next if url.strip.blank?

          depth = url.scan(/[^\/]+/).size
          next if depth > sitemap_depth

          if url =~ /#/
            data = { url: url.sub(/#.*/, ""), name: url.sub(/^.*?#/, ""), depth: depth }
          else
            url   = url.strip.sub(/\/$/, "")
            model = url =~ /(^|\/)[^\.]+$/ ? Cms::Node : Cms::Page

            if item = model.where(site_id: site_id).public.filename(url).first
              data = { url: item.url, name: item.name, depth: depth }
            else
              data = { url: url, name: url, depth: depth }
            end
          end

          if data[:depth] < sitemap_depth
            list << data
          else
            next if list.blank?
            list.last[:pages] ||= []
            list.last[:pages] << data
          end
        end

        list
      end

      def sitemap_xml
        site_url = site.full_url
        urls = sitemap_urls.presence || load_sitemap_urls

        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do |urlset|
            urlset.url do |url|
              url.loc site.full_url
              url.priority 1.0
            end

            urls.each do |pgae_url|
              urlset.url do |url|
                priority = "0.8"
                priority = "0.5" if pgae_url.scan("/").size > 2

                url.loc File.join(site_url, pgae_url)
                url.priority priority
              end
            end
          end
        end

        builder.to_xml
      end

    private
      def generate_sitemap_xml
        file = sitemap_xml_path
        data = sitemap_xml
        return if Fs.exists?(file) && data == Fs.read(file)
        Fs.write file, data
      end

      def remove_sitemap_xml
        file = sitemap_xml_path
        Fs.rm_rf(file) if Fs.file?(file)
      end

      def rename_sitemap_xml(src, dst)
        src = src.sub(/\.[^\/]+$/, ".xml")
        dst = dst.sub(/\.[^\/]+$/, ".xml")
        Fs.mv src, dst if Fs.exists?(src)
      end
  end
end
