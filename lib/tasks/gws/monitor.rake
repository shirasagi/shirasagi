namespace :gws do
  namespace :monitor do
    desc "deletion task"

    task :deletion => :environment do
      opts = {}
      gws_sites.each do |site|
        Rails.logger.info "#{site.name}の照会・回答削除開始。"
        Gws::Monitor::DeleteJob.bind(site_id:site.id).perform_now(opts)
      end
    end

    def gws_sites
      if name = ENV['site']
        return Gws::Group.where(name: name)
      end
    end
  end
end

