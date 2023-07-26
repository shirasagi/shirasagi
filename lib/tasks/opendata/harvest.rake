namespace :opendata do
  task harvest_datasets: :environment do
    Tasks::Opendata::Harvest.run
  end

  namespace :harvest do
    task run: :environment do
      Tasks::Opendata::Harvest.run
    end

    task export: :environment do
      Tasks::Opendata::Harvest.run(true, false)
    end

    task import: :environment do
      Tasks::Opendata::Harvest.run(false, true)
    end

    namespace :exporter do
      task dataset_purge: :environment do
        Tasks::Opendata::Harvest::Exporter.dataset_purge
      end

      task group_list: :environment do
        Tasks::Opendata::Harvest::Exporter.group_list
      end

      task organization_list: :environment do
        Tasks::Opendata::Harvest::Exporter.organization_list
      end

      task initialize_organization: :environment do
        Tasks::Opendata::Harvest::Exporter.initialize_organization
      end

      task initialize_group: :environment do
        Tasks::Opendata::Harvest::Exporter.initialize_group
      end
    end
  end
end
