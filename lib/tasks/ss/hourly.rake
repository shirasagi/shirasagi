namespace :ss do
  #
  # 0 * * * * bundle exec rake ss:hourly
  #
  task hourly: :environment do
    if ::SS.config.cms.disable.blank?
      ::Tasks::Cms.each_sites do |site|
        puts "# #{site.name} (#{site.host})"

        # サイト内検索の更新
        ::Tasks::SS.invoke_task("cms:es:feed_releases", site.host) if site.elasticsearch_enabled?

        # ページ書き出し
        # ::Tasks::SS.invoke_task("cms:generate_page")
      end

      # RSS取込
      ::Tasks::SS.invoke_task("rss:import_items")
    end

    # Multiple DB
    # ::Tasks::SS.invoke_task("ezine:pull_from_public")
    # ::Tasks::SS.invoke_task("inquiry:pull_answers")
  end
end
