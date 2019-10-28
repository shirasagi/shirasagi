namespace :history do
  namespace :trash do
    task purge: :environment do
      site = Cms::Site.find_by(host: ENV['site']) if ENV['site'].present?
      threshold = ENV['purge_threshold'] || ENV['threshold']
      params = []
      params << { threshold: threshold } if threshold.present?

      puts "delete history trashes"
      ::Rails.application.eager_load!
      History::Trash::TrashPurgeJob.bind(site_id: site).perform_now(*params)
    end

    task clear: :environment do
      Dir.glob "#{Rails.root}/private/trash/ss_files/**/_/**" do |file|
        if History::Trash.where(ref_coll: 'ss_files', 'data._id': File.basename(file).to_i).blank?
          FileUtils.rm(file)
        end
      end
    end
  end
end
