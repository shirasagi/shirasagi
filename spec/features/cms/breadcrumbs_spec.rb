require 'spec_helper'

#
# CMS メイン配下のパンくずリストに、親階層 (LINE / リンクチェック / 全コンテンツ /
# その他) が表示されることを feature レベルで保証する。
#
describe "cms breadcrumbs", type: :feature, dbscope: :example do
  let!(:site) { cms_site }

  before { login_cms_user }

  shared_examples "linked parent and leaf" do |parent_label, parent_path_method, leaf_label|
    it "shows '#{parent_label} > #{leaf_label}' under トップ" do
      visit visit_path

      within "#crumbs" do
        parent_crumb = find_link(parent_label, match: :first)
        expect(parent_crumb[:href]).to end_with(send(parent_path_method, site: site.id))
        expect(page).to have_content(leaf_label)
      end
    end
  end

  shared_examples "non-linked parent and leaf" do |parent_label, leaf_label|
    it "shows '#{parent_label} > #{leaf_label}' under トップ" do
      visit visit_path

      within "#crumbs" do
        expect(page).to have_content(parent_label)
        expect(page).to have_no_link(parent_label)
        expect(page).to have_content(leaf_label)
      end
    end
  end

  context "LINE" do
    let(:parent_label) { I18n.t("cms.line") }

    context "メッセージ" do
      let(:visit_path) { cms_line_messages_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_message")
    end

    context "統計情報" do
      let(:visit_path) { cms_line_statistics_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_statistics")
    end

    context "配信ログ" do
      let(:visit_path) { cms_line_deliver_logs_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_deliver_log")
    end

    context "配信条件" do
      let(:visit_path) { cms_line_deliver_conditions_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_deliver_condition")
    end

    context "配信カテゴリー" do
      let(:visit_path) { cms_line_deliver_categories_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_deliver_category")
    end

    context "メール連携" do
      let(:visit_path) { cms_line_mail_handlers_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_mail_handlers")
    end

    context "テストメンバー" do
      let(:visit_path) { cms_line_test_members_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_test_member")
    end

    context "リッチメニュー" do
      let(:visit_path) { cms_line_richmenu_groups_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_richmenu")
    end

    context "サービス" do
      let(:visit_path) { cms_line_service_groups_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_service")
    end

    context "セッション" do
      let(:visit_path) { cms_line_event_sessions_path(site) }
      include_examples "linked parent and leaf", I18n.t("cms.line"), :cms_line_messages_path, I18n.t("cms.line_event_session")
    end
  end

  context "リンクチェック" do
    context "レポート" do
      let(:visit_path) { cms_check_links_reports_path(site) }
      include_examples "linked parent and leaf",
        I18n.t("modules.cms/check_links"), :cms_check_links_path, I18n.t("cms/check_links.reports")
    end

    context "除外URL" do
      let(:visit_path) { cms_check_links_ignore_urls_path(site) }
      include_examples "linked parent and leaf",
        I18n.t("modules.cms/check_links"), :cms_check_links_path, I18n.t("cms/check_links.ignore_urls")
    end

    context "実行" do
      let(:visit_path) { cms_check_links_run_path(site) }
      include_examples "linked parent and leaf",
        I18n.t("modules.cms/check_links"), :cms_check_links_path, I18n.t("cms/check_links.run")
    end

    context "設定" do
      let(:visit_path) { cms_check_links_site_setting_path(site) }
      include_examples "linked parent and leaf",
        I18n.t("modules.cms/check_links"), :cms_check_links_path, I18n.t("cms/check_links.site_setting")
    end
  end

  context "全コンテンツ 無作為抽出" do
    let(:visit_path) { cms_all_contents_sampling_path(site) }
    include_examples "linked parent and leaf",
      I18n.t("cms.all_contents"), :cms_all_contents_path, I18n.t("cms.all_content.sampling_tab")
  end

  context "ゴミ箱" do
    it "shows 'ゴミ箱' as the leaf crumb" do
      visit history_cms_trashes_path(site)

      within "#crumbs" do
        expect(page).to have_content(History::Trash.model_name.human)
      end
    end
  end

  #
  # その他メニューはドロップダウン上のラベルで、独立したページを持たない。
  # 親パンくずはクリック不可 (path: nil) として表示する。
  #
  context "その他" do
    let(:parent_label) { I18n.t("cms.etc") }

    context "フォルダー取り込み" do
      let(:visit_path) { cms_import_path(site) }
      include_examples "non-linked parent and leaf", I18n.t("cms.etc"), I18n.t("cms.import_node")
    end

    context "フォルダー書き出し" do
      let(:visit_path) { cms_generate_nodes_path(site) }
      include_examples "non-linked parent and leaf", I18n.t("cms.etc"), I18n.t("cms.generate_node")
    end

    context "ページ書き出し" do
      let(:visit_path) { cms_generate_pages_path(site) }
      include_examples "non-linked parent and leaf", I18n.t("cms.etc"), I18n.t("cms.generate_page")
    end

    context "一括エクスポート" do
      let(:visit_path) { download_cms_nodes_path(site) }
      include_examples "non-linked parent and leaf", I18n.t("cms.etc"), I18n.t("cms.csv_export_node")
    end

    context "一括インポート" do
      let(:visit_path) { import_cms_nodes_path(site) }
      include_examples "non-linked parent and leaf", I18n.t("cms.etc"), I18n.t("cms.csv_import_node")
    end
  end

  #
  # 操作履歴メニュー配下 (操作履歴本体 / アーカイブ) のパンくずに
  # 親階層「操作履歴」を追加する。
  #
  context "操作履歴" do
    let(:parent_label) { I18n.t("history.log") }

    context "操作履歴" do
      let(:visit_path) { history_cms_logs_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("history.log"), :history_cms_logs_path, I18n.t("history.log")
    end

    context "アーカイブ" do
      let(:visit_path) { history_cms_history_archives_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("history.log"), :history_cms_logs_path,
                       I18n.t("mongoid.models.gws/history_archive_file")
    end
  end

  context "LDAP" do
    let(:parent_label) { I18n.t("ldap.links.ldap") }

    context "設定" do
      let(:visit_path) { cms_ldap_setting_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("ldap.links.ldap"), :cms_ldap_main_path, I18n.t("ldap.setting")
    end

    context "サーバー情報" do
      let(:visit_path) { cms_ldap_server_main_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("ldap.links.ldap"), :cms_ldap_main_path, I18n.t("ldap.server")
    end

    context "インポート" do
      let(:visit_path) { cms_ldap_imports_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("ldap.links.ldap"), :cms_ldap_main_path, I18n.t("ldap.import")
    end

    context "同期結果" do
      let(:visit_path) { cms_ldap_result_index_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("ldap.links.ldap"), :cms_ldap_main_path, I18n.t("ldap.result")
    end
  end

  context "ジョブ" do
    let(:parent_label) { I18n.t("job.main") }

    context "実行履歴" do
      let(:visit_path) { job_cms_logs_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("job.main"), :job_cms_main_path, I18n.t("job.log")
    end

    context "タスク" do
      let(:visit_path) { job_cms_tasks_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("job.main"), :job_cms_main_path, I18n.t("job.task")
    end

    context "実行予約" do
      let(:visit_path) { job_cms_reservations_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("job.main"), :job_cms_main_path, I18n.t("job.reservation")
    end

    context "miChecker結果" do
      let(:visit_path) { job_cms_michecker_results_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("job.main"), :job_cms_main_path, Cms::Michecker::Result.model_name.human
    end
  end

  context "自動翻訳" do
    let(:parent_label) { I18n.t("translate.main") }

    context "翻訳テキスト" do
      let(:visit_path) { cms_translate_text_caches_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("translate.main"), :cms_translate_main_path, I18n.t("translate.text_cache")
    end

    context "言語" do
      let(:visit_path) { cms_translate_langs_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("translate.main"), :cms_translate_main_path, I18n.t("translate.lang")
    end

    context "設定" do
      let(:visit_path) { cms_translate_site_setting_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("translate.main"), :cms_translate_main_path, I18n.t("translate.site_setting")
    end

    context "アクセス履歴" do
      let(:visit_path) { cms_translate_access_logs_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("translate.main"), :cms_translate_main_path, I18n.t("translate.access_log")
    end
  end

  context "レコメンド機能" do
    let(:parent_label) { I18n.t("recommend.main") }

    context "アクセス（トークン）" do
      let(:visit_path) { recommend_history_logs_tokens_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("recommend.main"), :recommend_history_logs_tokens_path, I18n.t("recommend.tokens")
    end

    context "アクセス（パス）" do
      let(:visit_path) { recommend_history_logs_paths_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("recommend.main"), :recommend_history_logs_tokens_path, I18n.t("recommend.paths")
    end

    context "類似度スコア" do
      let(:visit_path) { recommend_similarity_scores_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("recommend.main"), :recommend_history_logs_tokens_path, I18n.t("recommend.scores")
    end
  end

  context "読み上げ音声" do
    let(:parent_label) { I18n.t("voice.file") }

    context "ページ一覧" do
      let(:visit_path) { voice_files_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("voice.file"), :voice_files_path, I18n.t("views.voice/files.index")
    end

    context "エラー一覧" do
      let(:visit_path) { voice_error_files_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("voice.file"), :voice_files_path, I18n.t("views.voice/error_files.index")
    end
  end

  context "書き出し性能レポート" do
    let(:parent_label) { I18n.t("mongoid.models.cms/generation_report/title") }

    context "フォルダー書き出し" do
      let(:visit_path) { cms_generation_report_titles_path(site, type: "nodes") }
      include_examples "linked parent and leaf",
                       I18n.t("mongoid.models.cms/generation_report/title"),
                       :cms_generation_report_main_path, I18n.t("cms.generate_node")
    end

    context "ページ書き出し" do
      let(:visit_path) { cms_generation_report_titles_path(site, type: "pages") }
      include_examples "linked parent and leaf",
                       I18n.t("mongoid.models.cms/generation_report/title"),
                       :cms_generation_report_main_path, I18n.t("cms.generate_page")
    end
  end

  context "メンバー" do
    context "グループ" do
      let(:visit_path) { member_groups_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("cms.member"), :cms_members_path, I18n.t("member.group")
    end
  end

  context "定型フォーム" do
    context "定型フォーム - DB" do
      let(:visit_path) { cms_form_dbs_path(site) }
      include_examples "linked parent and leaf",
                       Cms::Form.model_name.human, :cms_forms_path, Cms::FormDb.model_name.human
    end
  end

  context "ソースクリーニング" do
    context "設定" do
      let(:visit_path) { cms_source_cleaner_site_setting_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("cms.source_cleaner"), :cms_source_cleaner_main_path,
                       I18n.t("translate.site_setting")
    end
  end

  context "かな" do
    context "診断" do
      let(:visit_path) { kana_diagnostic_path(site) }
      include_examples "non-linked parent and leaf",
                       I18n.t("modules.kana"), I18n.t("kana.diagnostic")
    end
  end

  context "SNS投稿連携" do
    context "投稿履歴" do
      let(:visit_path) { cms_sns_post_logs_path(site) }
      include_examples "linked parent and leaf",
                       I18n.t("cms.sns_post"), :cms_sns_post_logs_path, I18n.t("cms.sns_post_log")
    end
  end

  context "ページ検索" do
    it "shows 'ページ検索' as the leaf crumb" do
      visit cms_page_searches_path(site)

      within "#crumbs" do
        expect(page).to have_content(I18n.t("cms.page_search"))
      end
    end
  end

  context "書き出し停止" do
    it "shows '書き出し停止' as the leaf crumb" do
      visit cms_generate_lock_path(site)

      within "#crumbs" do
        expect(page).to have_content(I18n.t("modules.addons.ss/generate_lock"))
      end
    end
  end
end
