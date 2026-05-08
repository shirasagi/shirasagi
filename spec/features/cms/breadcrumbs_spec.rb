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
      include_examples "linked parent and leaf", I18n.t("modules.cms/check_links"), :cms_check_links_path, I18n.t("cms/check_links.reports")
    end

    context "除外URL" do
      let(:visit_path) { cms_check_links_ignore_urls_path(site) }
      include_examples "linked parent and leaf", I18n.t("modules.cms/check_links"), :cms_check_links_path, I18n.t("cms/check_links.ignore_urls")
    end

    context "実行" do
      let(:visit_path) { cms_check_links_run_path(site) }
      include_examples "linked parent and leaf", I18n.t("modules.cms/check_links"), :cms_check_links_path, I18n.t("cms/check_links.run")
    end

    context "設定" do
      let(:visit_path) { cms_check_links_site_setting_path(site) }
      include_examples "linked parent and leaf", I18n.t("modules.cms/check_links"), :cms_check_links_path, I18n.t("cms/check_links.site_setting")
    end
  end

  context "全コンテンツ 無作為抽出" do
    let(:visit_path) { cms_all_contents_sampling_path(site) }
    include_examples "linked parent and leaf", I18n.t("cms.all_contents"), :cms_all_contents_path, I18n.t("cms.all_content.sampling_tab")
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
end
