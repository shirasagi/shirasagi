require 'spec_helper'

describe "chorg_results", dbscope: :example do
  let(:site) { cms_site }
  let(:revision) { create(:revision, site_id: site.id) }
  let(:index_path) { chorg_results_results_path site.id, revision.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  describe "#index" do
    context "no items" do
      it do
        login_cms_user
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).not_to have_selector("table.index tbody tr")
      end
    end

    context "with item" do
      let(:job) { create(:job_model, cur_site: site) }
      let(:job_log) { create(:job_log, :job_log_running, job: job) }
      let(:revision) { create(:revision, site_id: site.id, job_ids: [job.id]) }
      let(:index_path) { chorg_results_results_path site.id, revision.id }

      it do
        # ensure that entities has existed.
        expect(job).not_to be_nil
        expect(job_log).not_to be_nil
        expect(revision).not_to be_nil

        login_cms_user
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_selector("table.index tbody tr")
      end
    end
  end

  describe "#show" do
    let(:job) { create(:job_model, cur_site: site) }
    let(:job_log) { create(:job_log, :job_log_running, job: job) }
    let(:revision) { create(:revision, site_id: site.id, job_ids: [job.id]) }
    let(:show_path) { chorg_results_result_path site.id, revision.id, job_log.id }

    it do
      # ensure that entities has existed.
      expect(job).not_to be_nil
      expect(job_log).not_to be_nil
      expect(revision).not_to be_nil

      login_cms_user
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).to eq show_path
      expect(page).to have_selector("div.addon-view dl.see")
    end
  end
end
