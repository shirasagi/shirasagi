require 'spec_helper'

#
# システム設定配下のパンくずリストに、親階層 (認証 / 診断 / ジョブ) が
# 表示されることを feature レベルで保証する。
#
# NOTE: ラベルは lambda で受け取り、example 実行時 (= ログイン後のロケール) に
# 評価する。spec 読み込み時に I18n.t を評価して固定すると、ログインユーザーの
# lang (SS::LocaleSupport.current_lang による en/ja のランダムサンプリング) で
# 描画されたページと不一致になり、ロケール次第で flaky に落ちるため。
#
describe "sys breadcrumbs", type: :feature, dbscope: :example do
  before { login_sys_user }

  shared_examples "has parent and leaf crumbs" do |parent_path_name|
    it "shows the parent and leaf crumbs under システム設定" do
      visit visit_path

      within "#crumbs" do
        parent_crumb = find_link(instance_exec(&parent_label))
        expect(parent_crumb[:href]).to end_with(send(parent_path_name))
        expect(page).to have_content(instance_exec(&leaf_label))
      end
    end
  end

  context "認証" do
    context "SAML" do
      let(:visit_path) { sys_auth_samls_path }
      let(:parent_label) { -> { I18n.t("sys.auth") } }
      let(:leaf_label) { -> { I18n.t("sys.auth/saml") } }
      include_examples "has parent and leaf crumbs", :sys_auth_path
    end

    context "OpenID Connect" do
      let(:visit_path) { sys_auth_open_id_connects_path }
      let(:parent_label) { -> { I18n.t("sys.auth") } }
      let(:leaf_label) { -> { I18n.t("sys.auth/open_id_connect") } }
      include_examples "has parent and leaf crumbs", :sys_auth_path
    end

    context "環境変数" do
      let(:visit_path) { sys_auth_environments_path }
      let(:parent_label) { -> { I18n.t("sys.auth") } }
      let(:leaf_label) { -> { I18n.t("sys.auth/environment") } }
      include_examples "has parent and leaf crumbs", :sys_auth_path
    end

    context "OAuthアプリ" do
      let(:visit_path) { sys_auth_oauth2_applications_path }
      let(:parent_label) { -> { I18n.t("sys.auth") } }
      let(:leaf_label) { -> { SS::OAuth2::Application::Base.model_name.human } }
      include_examples "has parent and leaf crumbs", :sys_auth_path
    end

    context "設定" do
      let(:visit_path) { sys_auth_setting_path }
      let(:parent_label) { -> { I18n.t("sys.auth") } }
      let(:leaf_label) { -> { I18n.t("sys.auth/setting") } }
      include_examples "has parent and leaf crumbs", :sys_auth_path
    end
  end

  context "診断" do
    context "MAIL Test" do
      let(:visit_path) { sys_diag_mails_path }
      let(:parent_label) { -> { I18n.t("sys.diag") } }
      let(:leaf_label) { -> { "MAIL Test" } }
      include_examples "has parent and leaf crumbs", :sys_diag_main_path
    end

    context "Server Info" do
      let(:visit_path) { sys_diag_server_path }
      let(:parent_label) { -> { I18n.t("sys.diag") } }
      let(:leaf_label) { -> { "Server Info" } }
      include_examples "has parent and leaf crumbs", :sys_diag_main_path
    end

    context "Application Log" do
      it "shows the parent crumb under システム設定" do
        visit sys_diag_app_log_path

        within "#crumbs" do
          parent_crumb = find_link(I18n.t("sys.diag"))
          expect(parent_crumb[:href]).to end_with(sys_diag_main_path)
        end
      end
    end
  end

  context "ジョブ" do
    context "実行履歴" do
      let(:visit_path) { job_sys_logs_path }
      let(:parent_label) { -> { I18n.t("job.main") } }
      let(:leaf_label) { -> { I18n.t("job.log") } }
      include_examples "has parent and leaf crumbs", :job_sys_main_path
    end

    context "タスク" do
      let(:visit_path) { job_sys_tasks_path }
      let(:parent_label) { -> { I18n.t("job.main") } }
      let(:leaf_label) { -> { I18n.t("job.task") } }
      include_examples "has parent and leaf crumbs", :job_sys_main_path
    end

    context "実行予約" do
      let(:visit_path) { job_sys_reservations_path }
      let(:parent_label) { -> { I18n.t("job.main") } }
      let(:leaf_label) { -> { I18n.t("job.reservation") } }
      include_examples "has parent and leaf crumbs", :job_sys_main_path
    end

    context "miChecker結果" do
      let(:visit_path) { job_sys_michecker_results_path }
      let(:parent_label) { -> { I18n.t("job.main") } }
      let(:leaf_label) { -> { Cms::Michecker::Result.model_name.human } }
      include_examples "has parent and leaf crumbs", :job_sys_main_path
    end

    context "状態" do
      let(:visit_path) { job_sys_status_path }
      let(:parent_label) { -> { I18n.t("job.main") } }
      let(:leaf_label) { -> { I18n.t("job.status") } }
      include_examples "has parent and leaf crumbs", :job_sys_main_path
    end
  end

  #
  # システム設定 > 操作履歴 > 操作履歴。操作履歴一覧ページのパンくずに
  # 親階層「操作履歴」と leaf「操作履歴」が表示されることを保証する。
  #
  context "操作履歴" do
    let(:visit_path) { history_sys_logs_path }
    let(:parent_label) { -> { I18n.t("mongoid.models.gws/history") } }
    let(:leaf_label) { -> { I18n.t("history.log") } }
    include_examples "has parent and leaf crumbs", :history_sys_logs_path
  end

  #
  # システム設定 > 操作履歴 > アーカイブ。アーカイブ一覧ページのパンくずに
  # 親階層「操作履歴」と leaf「アーカイブ」が表示されることを保証する。
  #
  context "操作履歴アーカイブ" do
    let(:visit_path) { sys_history_archives_path }
    let(:parent_label) { -> { I18n.t("mongoid.models.gws/history") } }
    let(:leaf_label) { -> { I18n.t("mongoid.models.gws/history_archive_file") } }
    include_examples "has parent and leaf crumbs", :history_sys_logs_path
  end
end
