require 'spec_helper'

describe "cms/check_links/run", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:index_path) { cms_check_links_run_path site.id }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path

      within "form#task-form" do
        click_on I18n.t("ss.buttons.run")
      end
      wait_for_notice I18n.t("ss.tasks.started")

      expect(enqueued_jobs.length).to eq 1
      enqueued_jobs.first.tap do |enqueued_job|
        expect(enqueued_job[:job]).to eq Cms::CheckLinksJob
      end
    end
  end
end
