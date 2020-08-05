module Tasks
  module Cms
    class << self
      def generate_nodes
        each_sites do |site|
          if ENV.key?("node")
            with_node(site, ENV["node"]) do |node|
              perform_job(::Cms::Node::GenerateJob, site: site, node: node)
            end
          else
            perform_job(::Cms::Node::GenerateJob, site: site)
          end
        end
      end

      def generate_pages
        each_sites do |site|
          if ENV.key?("node")
            with_node(site, ENV["node"]) do |node|
              perform_job(::Cms::Page::GenerateJob, site: site, node: node)
            end
          else
            perform_job(::Cms::Page::GenerateJob, site: site)
          end
        end
      end

      def update_pages
        each_sites do |site|
          if ENV.key?("node")
            with_node(site, ENV["node"]) do |node|
              perform_job(::Cms::Page::UpdateJob, site: site, node: node)
            end
          else
            perform_job(::Cms::Page::UpdateJob, site: site)
          end
        end
      end

      def release_pages
        each_sites do |site|
          perform_job(::Cms::Page::ReleaseJob, site: site)
        end
      end

      def remove_pages
        each_sites do |site|
          perform_job(::Cms::Page::RemoveJob, site: site)
        end
      end

      def check_links
        each_sites do |site|
          if ENV.key?("node")
            with_node(site, ENV["node"]) do |node|
              perform_job(::Cms::CheckLinksJob, site: site, node: node, email: ENV["email"])
            end
          else
            perform_job(::Cms::CheckLinksJob, site: site, email: ENV["email"])
          end
        end
      end

      def import_files
        each_sites do |site|
          perform_job(::Cms::ImportFilesJob, site: site)
        end
      end

      def export_site
        with_site(ENV['site']) do |site|
          job = ::Sys::SiteExportJob.new
          job.task = mock_task(
            source_site_id: site.id
          )
          job.perform
        end
      end

      def import_site
        with_site(ENV['site']) do |site|
          puts "Please input import file: file=[file_path]" or break if ENV['file'].blank?

          file = ENV['file']
          puts "File not found: #{ENV['file']}" or break unless ::File.exist?(file)

          job = ::Sys::SiteImportJob.new
          job.task = mock_task(
            target_site_id: site.id,
            import_file: file
          )
          job.perform
        end
      end

      def reload_site_usage
        puts "# reload site usage"
        each_sites do |site|
          begin
            puts "#{site.host}: #{site.name}"
            site.reload_usage!
          rescue => e
            Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
            puts("Failed to update usage: #{site.host}")
          end
        end
      end

      def set_subdir_url
        with_site(ENV['site']) do |site|
          puts "# layouts"
          gsub_attrs(::Cms::Layout.site(site), site)

          puts "# parts"
          gsub_attrs(::Cms::Part.site(site), site)

          puts "# pages"
          gsub_attrs(::Cms::Page.site(site), site)

          puts "# nodes"
          gsub_attrs(::Cms::Node.site(site), site)

          puts "# member/login"
          each_items(::Member::Node::Login.site(site)) do |item|
            if item.redirect_url.start_with?("/")
              item.set(redirect_url: "#{site.url}#{item.redirect_url[1..-1]}")
            end
          end

          site.mobile_location = "#{site.url}#{site.mobile_location[1..-1]}" if site.mobile_location.present?
          site.editor_css_path = "#{site.url}#{site.editor_css_path[1..-1]}" if site.editor_css_path.present?
        end
      end

      def each_sites
        name = ENV['site']
        if name
          all_ids = ::Cms::Site.where(host: name).pluck(:id)
        elsif ENV.key?('include_sites')
          names = ENV['include_sites'].split(/[, 　、\r\n]+/)
          all_ids = ::Cms::Site.in(host: names).pluck(:id)
        else
          all_ids = ::Cms::Site.all.pluck(:id)
        end

        if ENV.key?('exclude_sites')
          names = ENV['exclude_sites'].split(/[, 　、\r\n]+/)
          exclude_ids = ::Cms::Site.in(host: names).pluck(:id)
          all_ids -= exclude_ids
        end

        all_ids.each_slice(20) do |ids|
          ::Cms::Site.where(:id.in => ids).each do |site|
            yield site
          end
        end
      end

      def with_site(name)
        if name.blank?
          puts "Please input site_name: site=[site_name]"
          return
        end

        site = ::Cms::Site.where(host: name).first
        if !site
          puts "Site not found: #{name}"
          return
        end

        yield site
      end

      def with_node(site, name)
        if name.blank?
          puts "Please input node_name: node=[node_name]"
          return
        end

        node = ::Cms::Node.site(site).where(filename: name).first
        if !node
          puts "Node not found under site #{site.host}: #{name}"
          return
        end

        node = node.becomes_with_route rescue node
        yield node
      end

      def each_items(criteria)
        all_ids = criteria.pluck(:id).sort
        all_ids.each_slice(20) do |ids|
          criteria.in(id: ids).to_a.each do |item|
            yield item
          end
        end
      end

      def perform_job(job_class, opts = {})
        job = job_class.bind(site_id: opts.delete(:site))
        job = job.bind(node_id: opts.delete(:node)) if opts.key?(:node)
        job.perform_now(opts)
      end

      def mock_task(attr)
        task = OpenStruct.new(attr)
        def task.log(msg)
          puts(msg)
        end
        task
      end

      def gsub_path(html, site)
        html.gsub(/(href|src)=".*?"/) do |m|
          url = m.match(/.*?="(.*?)"/)[1]
          if url.start_with?("/assets/", "/assets-dev/", "/fs/")
            m
          elsif url.start_with?(site.url)
            m
          elsif /^\/(?!\/)/.match?(url)
            m.sub(/="\//, "=\"#{site.url}")
          else
            m
          end
        end
      end

      def gsub_attrs(criteria, site)
        all_ids = criteria.pluck(:id)
        all_ids.each_slice(100) do |ids|
          criteria.klass.where(:id.in => ids).each do |item|
            item = item.becomes_with_route
            attrs = %w(html upper_html lower_html roop_html)
            attrs.each do |attr|
              next unless item.respond_to?(attr) && item.respond_to?("#{attr}=")
              next unless item.send(attr).present?

              item.send("#{attr}=", gsub_path(item.send(attr), site))
            end
            item.save!

            puts item.name
          end
        end
      end
    end
  end
end
