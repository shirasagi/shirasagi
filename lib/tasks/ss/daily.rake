namespace :ss do
  #
  # 5 0 * * * bundle exec rake ss:daily
  #
  task daily: :environment do
    # 一時ファイルの削除（エクスポート）
    Rake.application.invoke_task("ss:delete_download_files")

    # 一時ファイルの削除（アクセストークン）
    Rake.application.invoke_task("ss:delete_access_tokens")

    if SS.config.cms.disable.blank?
      # ゴミ箱の掃除
      Rake.application.invoke_task("history:trash:purge")

      ::Tasks::Cms.each_sites do |site|
        # クローリングリソースの更新
        Rake.application.invoke_task("opendata:crawl[#{site.host}]")

        # スコア計算（リコメンド機能）
        Rake.application.invoke_task("recommend:create_similarity_scores[#{site.host}]") if SS.config.recommend.disable.blank?

        # リンクチェック
        # Rake.application.invoke_task("cms:check_links[#{site.host}, 'admin@example.jp']")
      end
    end

    if SS.config.gws.disable.blank?
      # ゴミ箱の掃除
      Rake.application.invoke_task("gws:trash:purge")
    end
  end
end
