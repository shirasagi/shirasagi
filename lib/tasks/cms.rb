module Tasks
  class Cms
    class << self
      def generate_nodes
        with_node(::Cms::Node::GenerateJob)
      end

      def generate_pages
        with_node(::Cms::Page::GenerateJob, attachments: ENV["attachments"])
      end

      def update_pages
        with_node(::Cms::Page::UpdateJob)
      end

      def release_pages
        with_site(::Cms::Page::ReleaseJob)
      end

      def remove_pages
        with_site(::Cms::Page::RemoveJob)
      end

      def check_links
        with_node(::Cms::CheckLinksJob, email: ENV["email"])
      end

      def import_files
        ::Cms::ImportFilesJob.perform_now
      end

      def export_site
        puts "Please input site name: site=[site_name]" or exit if ENV['site'].blank?

        site = ::SS::Site.where(host: ENV['site']).first
        puts "Site not found: #{ENV['site']}" or exit unless site

        job = ::Sys::SiteExportJob.new
        job.task = mock_task(
          source_site_id: site.id
        )
        job.perform
      end

      def import_site
        puts "Please input site name: site=[site_name]" or exit if ENV['site'].blank?
        puts "Please input import file: site=[site_name]" or exit if ENV['file'].blank?

        site = ::SS::Site.where(host: ENV['site']).first
        puts "Site not found: #{ENV['site']}" or exit unless site

        file = ENV['file']
        puts "File not found: #{ENV['file']}" or exit unless ::File.exist?(file)

        job = ::Sys::SiteImportJob.new
        job.task = mock_task(
          target_site_id: site.id,
          import_file: file
        )
        job.perform
      end

      def set_subdir_url
        puts "Please input site_name: site=[site_name]" or exit if ENV['site'].blank?

        @site = ::SS::Site.where(host: ENV['site']).first
        puts "Site not found: #{ENV['site']}" or exit unless @site

        puts "# layouts"
        gsub_attrs(::Cms::Layout)

        puts "# parts"
        gsub_attrs(::Cms::Part)

        puts "# pages"
        gsub_attrs(::Cms::Page)

        puts "# nodes"
        gsub_attrs(::Cms::Node)
      end

      private

      def find_sites(site)
        return ::Cms::Site unless site
        ::Cms::Site.where host: site
      end

      def with_site(job_class, opts = {})
        find_sites(ENV["site"]).each do |site|
          job = job_class.bind(site_id: site)
          job.perform_now(opts)
        end
      end

      def with_node(job_class, opts = {})
        find_sites(ENV["site"]).each do |site|
          job = job_class.bind(site_id: site)
          job = job.bind(node_id: ::Cms::Node.site(site).find_by(filename: ENV["node"]).id) if ENV["node"]
          job.perform_now(opts)
        end
      end

      def mock_task(attr)
        task = OpenStruct.new(attr)
        def task.log(msg)
          puts(msg)
        end
        task
      end

      def gsub_path(html)
        html.gsub(/(href|src)=".*?"/) do |m|
          url = m.match(/.*?="(.*?)"/)[1]
          if url =~ /^\/(assets|assets-dev|fs)\//
            m
          elsif url =~ /^#{@site.url}/
            m
          elsif url =~ /^\/(?!\/)/
            m.sub(/="\//, "=\"#{@site.url}")
          else
            m
          end
        end
      end

      def gsub_attrs(model)
        ids = model.site(@site).pluck(:id)
        ids.each do |id|
          item = model.find(id) rescue nil
          next unless item

          item = item.becomes_with_route
          attrs = %w(html upper_html lower_html roop_html)
          attrs.each do |attr|
            next unless item.respond_to?(attr) && item.respond_to?("#{attr}=")
            next unless item.send(attr).present?
            item.send("#{attr}=", gsub_path(item.send(attr)))
          end
          item.save!

          puts item.name
        end
      end
    end
  end
end
