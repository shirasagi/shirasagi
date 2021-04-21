namespace :history do
  namespace :trash do
    task purge: :environment do
      sites = Cms::Site.all
      sites = site.where(host: ENV['site']) if ENV['site'].present?
      threshold = ENV['purge_threshold'] || ENV['threshold']
      params = []
      params << { threshold: threshold } if threshold.present?

      puts "delete history trashes"
      ::Rails.application.eager_load!
      sites.each do |site|
        History::Trash::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      end
    end

    task clear: :environment do
      ids = History::Trash.where(ref_coll: 'ss_files').collect do |item|
        item.data['_id']
      end
      Dir.glob("#{Rails.root}/private/trash/ss_files/**/_/**") do |file|
        if !ids.include?(File.basename(file).to_i)
          Fs.rm_rf(file)
        end
      end
    end
  end
end
