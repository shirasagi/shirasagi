require 'spec_helper'

describe "job_cms_logs" do
  subject(:site) { cms_site }
  # subject(:model) { Job::Log }
  subject(:index_path) { job_cms_logs_path site.host }
  subject(:download_path) { job_cms_download_path site.host }
  subject(:batch_destroy) { job_cms_batch_destroy_path site.host }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#download" do
      visit download_path
      expect(status_code).to eq 200
      expect(current_path).to eq download_path

      within "form" do
        click_button I18n.t(:download, scope: "views")
      end

      expect(status_code).to eq 200
    end

    it "#batch_destroy" do
      visit batch_destroy
      expect(status_code).to eq 200
      expect(current_path).to eq batch_destroy

      within "form" do
        click_button I18n.t("button.delete", scope: "views")
      end
      expect(status_code).to eq 200
    end
  end
end
