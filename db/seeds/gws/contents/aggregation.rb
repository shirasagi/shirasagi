puts "# gws/aggregation"
puts "\# #{@site.name}"
::Gws::Aggregation::GroupUpdateJob.bind(site_id: @site.id).perform_now
