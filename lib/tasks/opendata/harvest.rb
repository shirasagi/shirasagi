module Tasks
  module Opendata
    module Harvest
      module_function

      def env_exporters
        return if !ENV.key?('exporter') && !ENV.key?('exporters')

        exporters = []
        exporters += [ENV['exporter']] if ENV.key?('exporter')
        exporters += ENV['exporters'].split(/[, 　、\r\n]+/) if ENV.key?('exporters')
        exporters
      end

      def env_importers
        return if !ENV.key?('importer') && !ENV.key?('importers')

        importers = []
        importers += [ENV['importer']] if ENV.key?('importer')
        importers += ENV['importers'].split(/[, 　、\r\n]+/) if ENV.key?('importers')
        importers
      end

      def run
        ::Tasks::Cms.with_site(ENV['site']) do |site|
          exporters = env_exporters
          importers = env_importers

          opts = {}
          opts[:exporters] = exporters if exporters.present?
          opts[:importers] = importers if importers.present?
          ::Opendata::Harvest::RunJob.bind(site_id: site.id).perform_now(opts)
        end
      end

      def export
        ::Tasks::Cms.with_site(ENV['site']) do |site|
          exporters = env_exporters

          opts = {}
          opts[:exporters] = exporters if exporters.present?
          ::Opendata::Harvest::ExportJob.bind(site_id: site.id).perform_now(opts)
        end
      end

      def import
        ::Tasks::Cms.with_site(ENV['site']) do |site|
          importers = env_importers

          opts = {}
          opts[:importers] = importers if importers.present?
          ::Opendata::Harvest::ImportJob.bind(site_id: site.id).perform_now(opts)
        end
      end

      module Exporter
        module_function

        def with_exporter(site, id)
          if id.blank?
            puts "Please input exporter: exporter=[1]"
            return
          end

          exporter = ::Opendata::Harvest::Exporter.site(site).find(id) rescue nil
          if !exporter
            puts "Exporter not found: #{id}"
            return
          end

          yield exporter
        end

        def dataset_purge
          ::Tasks::Cms.with_site(ENV['site']) do |site|
            with_exporter(site, ENV['exporter']) do |exporter|
              exporter.dataset_purge
            end
          end
        end

        def group_list
          ::Tasks::Cms.with_site(ENV['site']) do |site|
            with_exporter(site, ENV['exporter']) do |exporter|
              exporter.group_list
            end
          end
        end

        def organization_list
          ::Tasks::Cms.with_site(ENV['site']) do |site|
            with_exporter(site, ENV['exporter']) do |exporter|
              exporter.organization_list
            end
          end
        end

        def initialize_organization
          ::Tasks::Cms.with_site(ENV['site']) do |site|
            with_exporter(site, ENV['exporter']) do |exporter|
              exporter.initialize_organization
            end
          end
        end

        def initialize_group
          ::Tasks::Cms.with_site(ENV['site']) do |site|
            with_exporter(site, ENV['exporter']) do |exporter|
              exporter.initialize_group
            end
          end
        end
      end
    end
  end
end
