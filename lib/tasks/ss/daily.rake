namespace :ss do
  #
  # 5 0 * * * bundle exec rake ss:daily
  #
  task daily: :environment do
    # 一時ファイルの削除（エクスポート）
    ::Tasks::SS.invoke_task("ss:delete_download_files")

    # 一時ファイルの削除（CMSお問い合わせ）
    ::Tasks::SS.invoke_task("inquiry:delete_inquiry_temp_files")

    # 一時ファイルの削除（アクセストークン）
    ::Tasks::SS.invoke_task("ss:delete_access_tokens")

    if ::SS.config.cms.disable.blank?
      # ゴミ箱の掃除
      ::Tasks::SS.invoke_task("history:trash:purge")

      # history_logの削除
      ::Tasks::SS.invoke_task("history:history_log:purge")

      ::Tasks::Cms.each_sites do |site|
        # クローリングリソースの更新
        ::Tasks::SS.invoke_task("opendata:crawl", site.host)

        # スコア計算（リコメンド機能）
        ::Tasks::SS.invoke_task("recommend:create_similarity_scores", site.host) if ::SS.config.recommend.disable.blank?

        # 公開ファイルの一貫性チェック - 誤って公開されているファイルの削除
        ::SS::PublicFileRemoverJob.bind(site_id: site).perform_now

        # リンクチェック
        # ::Tasks::SS.invoke_task("cms:check_links", site.host, 'admin@example.jp']")

        # オープンデータのレポート作成
        ::Tasks::SS.invoke_task("opendata:report:generate_download", site.host)
        ::Tasks::SS.invoke_task("opendata:report:generate_access", site.host)
        ::Tasks::SS.invoke_task("opendata:report:generate_preview", site.host)
      end

      # 各種使用率の更新
      ::Tasks::SS.invoke_task("cms:reload_site_usage")
    end

    if ::SS.config.gws.disable.blank?
      # ゴミ箱の掃除
      ::Tasks::SS.invoke_task("gws:trash:purge")

      # 各種使用率の更新
      ::Tasks::SS.invoke_task("gws:reload_site_usage")
    end
  end
end
