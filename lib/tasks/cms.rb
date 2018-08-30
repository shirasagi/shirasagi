module Tasks
  class Cms
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
              perform_job(::Cms::Page::GenerateJob, site: site, node: node, attachments: ENV["attachments"])
            end
          else
            perform_job(::Cms::Page::GenerateJob, site: site, attachments: ENV["attachments"])
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
        ::Cms::ImportFilesJob.perform_now
      end

      def export_site
        with_site do |site|
          job = ::Sys::SiteExportJob.new
          job.task = mock_task(
            source_site_id: site.id
          )
          job.perform
        end
      end

      def import_site
        with_site do |site|
          puts "Please input import file: site=[site_name]" or break if ENV['file'].blank?

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

      def set_subdir_url
        with_site do |site|
          puts "# layouts"
          gsub_attrs(::Cms::Layout.site(site))

          puts "# parts"
          gsub_attrs(::Cms::Part.site(site))

          puts "# pages"
          gsub_attrs(::Cms::Page.site(site))

          puts "# nodes"
          gsub_attrs(::Cms::Node.site(site))
        end
      end

      def each_sites
        name = ENV['site']
        if name
          all_ids = ::Cms::Site.where(host: name).pluck(:id)
        else
          all_ids = ::Cms::Site.all.pluck(:id)
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

      def gsub_attrs(criteria)
        all_ids = criteria.pluck(:id)
        all_ids.each_slice(100) do |ids|
          criteria.klass.where(:id.in => ids).each do |item|
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
end
