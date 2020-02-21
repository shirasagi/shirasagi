namespace :ss do
  #
  # */10 * * * * bundle exec rake ss:timely
  #
  task timely: :environment do
    if SS.config.gws.disable.blank?
      # 通知
      Rake.application.invoke_task("gws:notification:deliver")
    end

    if SS.config.cms.disable.blank?
      # ページ予約公開
      # Rake.application.invoke_task("cms:release_pages")

      # ページ書き出し（フォルダー）
      # Rake.application.invoke_task("cms:generate_nodes")

      # メールマガジン配信予約
      # Rake.application.invoke_task("ezine:deliver")
    end
  end
end
