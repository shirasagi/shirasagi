namespace :facility do
  task clear_search_cache: :environment do
    criteria = Facility::Node::Page.all

    puts "# Total #{criteria.size} pages"

    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      puts "find 100 pages..."

      criteria.klass.where(:id.in => ids).each do |item|
        item.save
      end
    end
  end
end
