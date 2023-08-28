namespace :facility do
  task clear_search_cache: :environment do
    site_map = Cms::Site.all.to_a.index_by { |site| site.id }

    criteria = Facility::Node::Page.all
    puts "# Total #{criteria.size.to_s(:delimited)} pages"

    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      puts "find #{ids.length.to_s(:delimited)} pages..."

      criteria.in(id: ids).to_a.each do |item|
        site = site_map[item.site_id]
        next if site.blank?

        item.cur_site = site
        item.save
      end
    end
  end
end
