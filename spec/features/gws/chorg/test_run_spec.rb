require 'spec_helper'

describe "gws_chorg", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let!(:revision) { create(:gws_revision, site_id: site.id) }

  before { login_gws_user }

  context "execute test run" do
    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.test_execute")

      expectation = expect do
        within "form#item-form" do
          click_on I18n.t("chorg.views.run/confirmation.test.run_button")
        end
      end
      expectation.to have_enqueued_job(Gws::Chorg::TestRunner)
      expect(page).to have_css("#notice", text: I18n.t('chorg.messages.job_started'))
    end
  end

  context "test run result" do
    let!(:task) do
      Gws::Chorg::Task.site(site).and_revision(revision).where(name: "gws:chorg:test_task").first_or_create
    end

    before do
      expect do
        Gws::Chorg::TestRunner.bind(site_id: site.id, user_id: gws_user.id, task_id: task.id).perform_now(revision.name, {})
      end.to output(include("成功: 0, 失敗: 0\n")).to_stdout
    end

    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.test_execute")
      click_on "結果"
      expect(page).to have_content("成功: 0, 失敗: 0")
    end
  end
end
