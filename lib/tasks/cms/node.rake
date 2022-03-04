namespace :cms do
  task generate_nodes: :environment do
    ::Tasks::Cms.generate_nodes
  end

  task release_nodes: :environment do
    ::Tasks::Cms.release_nodes
  end
end
