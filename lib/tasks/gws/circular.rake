namespace :gws do
  namespace :circular do
    desc 'circular deletion task'

    task :deletion => :environment do
      opts = {}
      gws_sites.each do |site|
        Rails.logger.info "#{site.name}の回覧板削除開始。"
        Gws::Circular::DeleteJob.bind(site_id:site.id).perform_now(opts)
      end
    end

    def gws_sites
      if name = ENV['site']
        return Gws::Group.where(name: name)
      end

      ids = Gws::Group.all.map { |group| group.root.try(:id) }.uniq.compact
      Gws::Group.where(:id.in => ids)
    end
  end
end

