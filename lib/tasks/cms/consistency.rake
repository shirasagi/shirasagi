namespace :cms do
  namespace :consistency do
    task check: :environment do
      ::Tasks::Cms.consistency_check
    end

    task repair: :environment do
      ::Tasks::Cms.consistency_repair
    end
  end
end
