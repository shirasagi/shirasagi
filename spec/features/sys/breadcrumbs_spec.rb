require 'spec_helper'

#
# システム設定配下のパンくずリストに、親階層 (認証 / 診断 / ジョブ) が
# 表示されることを feature レベルで保証する。
#
describe "sys breadcrumbs", type: :feature, dbscope: :example do
  before { login_sys_user }

  shared_examples "has parent and leaf crumbs" do |parent_label, parent_path_name, leaf_label|
    it "shows '#{parent_label} > #{leaf_label}' under システム設定" do
      visit visit_path

      within "#crumbs" do
        parent_crumb = find_link(parent_label)
        expect(parent_crumb[:href]).to end_with(send(parent_path_name))
        expect(page).to have_content(leaf_label)
      end
    end
  end

  context "認証" do
    context "SAML" do
      let(:visit_path) { sys_auth_samls_path }
      include_examples "has parent and leaf crumbs", I18n.t("sys.auth"), :sys_auth_path, I18n.t("sys.auth/saml")
    end

    context "OpenID Connect" do
      let(:visit_path) { sys_auth_open_id_connects_path }
      include_examples "has parent and leaf crumbs", I18n.t("sys.auth"), :sys_auth_path, I18n.t("sys.auth/open_id_connect")
    end

    context "環境変数" do
      let(:visit_path) { sys_auth_environments_path }
      include_examples "has parent and leaf crumbs", I18n.t("sys.auth"), :sys_auth_path, I18n.t("sys.auth/environment")
    end

    context "OAuthアプリ" do
      let(:visit_path) { sys_auth_oauth2_applications_path }
      include_examples "has parent and leaf crumbs", I18n.t("sys.auth"), :sys_auth_path, SS::OAuth2::Application::Base.model_name.human
    end

    context "設定" do
      let(:visit_path) { sys_auth_setting_path }
      include_examples "has parent and leaf crumbs", I18n.t("sys.auth"), :sys_auth_path, I18n.t("sys.auth/setting")
    end
  end

  context "診断" do
    context "MAIL Test" do
      let(:visit_path) { sys_diag_mails_path }
      include_examples "has parent and leaf crumbs", I18n.t("sys.diag"), :sys_diag_main_path, "MAIL Test"
    end

    context "Server Info" do
      let(:visit_path) { sys_diag_server_path }
      include_examples "has parent and leaf crumbs", I18n.t("sys.diag"), :sys_diag_main_path, "Server Info"
    end

    context "Application Log" do
      it "shows '#{I18n.t('sys.diag')}' as the parent crumb" do
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
      include_examples "has parent and leaf crumbs", I18n.t("job.main"), :job_sys_main_path, I18n.t("job.log")
    end

    context "タスク" do
      let(:visit_path) { job_sys_tasks_path }
      include_examples "has parent and leaf crumbs", I18n.t("job.main"), :job_sys_main_path, I18n.t("job.task")
    end

    context "実行予約" do
      let(:visit_path) { job_sys_reservations_path }
      include_examples "has parent and leaf crumbs", I18n.t("job.main"), :job_sys_main_path, I18n.t("job.reservation")
    end

    context "miChecker結果" do
      let(:visit_path) { job_sys_michecker_results_path }
      include_examples "has parent and leaf crumbs", I18n.t("job.main"), :job_sys_main_path, Cms::Michecker::Result.model_name.human
    end

    context "状態" do
      let(:visit_path) { job_sys_status_path }
      include_examples "has parent and leaf crumbs", I18n.t("job.main"), :job_sys_main_path, I18n.t("job.status")
    end
  end

  #
  # システム設定 > 操作履歴 > アーカイブ。現状は leaf が「操作履歴」になっていたが、
  # 本ページは履歴のアーカイブ一覧であるため leaf を「アーカイブ」へ修正する。
  #
  context "操作履歴アーカイブ" do
    it "shows 'アーカイブ' as the leaf crumb" do
      visit sys_history_archives_path

      within "#crumbs" do
        archive_label = I18n.t("mongoid.models.gws/history_archive_file")
        expect(page).to have_content(archive_label)
      end
    end
  end
end
