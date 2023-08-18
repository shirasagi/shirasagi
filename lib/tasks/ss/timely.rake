namespace :ss do
  #
  # */10 * * * * bundle exec rake ss:timely
  #
  task timely: :environment do
    if ::SS.config.gws.disable.blank?
      # 通知
      ::Tasks::SS.invoke_task("gws:notification:deliver")
    end

    if ::SS.config.cms.disable.blank?
      # ページ予約公開
      # ::Tasks::SS.invoke_task("cms:release_pages")

      # ページ書き出し（フォルダー）
      # ::Tasks::SS.invoke_task("cms:generate_nodes")

      # メールマガジン配信予約
      # ::Tasks::SS.invoke_task("ezine:deliver")
    end
  end
end
