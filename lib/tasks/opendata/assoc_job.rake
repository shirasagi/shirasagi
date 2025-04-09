namespace :opendata do
  namespace :assoc_job do
    task :perform, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        puts "# #{site.name}"
        nodes = Cms::Node.site(site).
          ne(opendata_site_ids: []).
          exists(opendata_site_ids: true)
        ::Tasks::Cms.each_items(nodes) do |node|
          dataset_sites = node.opendata_sites
          ::Tasks::Cms.each_items(dataset_sites).each do |dataset_site|
            puts node.name
            job = Opendata::CmsIntegration::AssocJob.bind(site_id: dataset_site)
            job.perform_now(site.id, node.id, nil, 'create_or_update')
          end
        end
      end
    end
  end
end
