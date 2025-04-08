namespace :opendata do
  namespace :assoc_job do
    task perform: :environment do
      ::Tasks::Cms.each_sites do |site|
        puts "# #{site.name}"
        nodes = Cms::Node.site(site).
          ne(opendata_site_ids: []).
          exists(opendata_site_ids: true)
        ::Tasks::Cms.each_items(nodes) do |node|
          items = Cms::Page.site(site).node(node)
          ::Tasks::Cms.each_items(items) do |item|
            puts item.name
            job = Opendata::CmsIntegration::AssocJob.bind(site_id: site, node_id: node)
            job.perform_now(site.id, node.id, item.id, 'create_or_update')
          end
        end
      end
    end
  end
end
