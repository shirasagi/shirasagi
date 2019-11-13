namespace :ss do
  #
  # 0 * * * * bundle exec rake ss:hourly
  #
  task hourly: :environment do
    if SS.config.cms.disable.blank?
      ::Tasks::Cms.each_sites do |site|
        puts "# #{site.name} (#{site.host})"

        # ページ書き出し
        # Rake.application.invoke_task("cms:generate_page")

        # サイト内検索の更新
        Rake.application.invoke_task("cms:es:feed_releases[#{site.host}]") if site.elasticsearch_enabled?
      end

      # RSS取込
      Rake.application.invoke_task("rss:import_items")
    end
  end
end
