require 'spec_helper'

describe "chorg_run", dbscope: :example do
  let(:site) { cms_site }
  let(:revision) { create(:revision, site_id: site.id) }
  let(:changeset) { create(:add_changeset, revision_id: revision.id) }
  let(:revision_show_path) { chorg_revisions_revision_path site.id, revision.id }

  context "with test run" do
    let(:test_run_path) { chorg_run_confirmation_path site.id, revision.id, "test" }

    it "without login" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      visit test_run_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      login_ss_user
      visit test_run_path
      expect(status_code).to eq 403
    end

    it "runs test" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      login_cms_user
      visit test_run_path
      expect(status_code).to eq 200
      within "form#item-form" do
        click_button I18n.t("chorg.views.run/confirmation.test.run_button")
      end
      expect(status_code).to eq 200
      expect(current_path).to eq revision_show_path
      revision.reload
      expect(revision.job_ids.length).to eq 1
      # job should be started within 1.minute
      Timeout.timeout(60) do
        loop do
          count = Job::Log.where(site_id: site.id, job_id: revision.job_ids.first).count
          break if count > 0
          sleep 0.1
        end
      end
      log = Job::Log.where(site_id: site.id, job_id: revision.job_ids.first).first
      expect(log).not_to be_nil
    end
  end

  context "with main run" do
    let(:main_run_path) { chorg_run_confirmation_path site.id, revision.id, "main" }

    it "without login" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      visit main_run_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      login_ss_user
      visit main_run_path
      expect(status_code).to eq 403
    end

    it "runs main" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      login_cms_user
      visit main_run_path
      expect(status_code).to eq 200
      within "form#item-form" do
        click_button I18n.t("chorg.views.run/confirmation.main.run_button")
      end
      expect(status_code).to eq 200
      expect(current_path).to eq revision_show_path
      revision.reload
      expect(revision.job_ids.length).to eq 1
      # job should be started within 1.minute
      Timeout.timeout(60) do
        loop do
          count = Job::Log.where(site_id: site.id, job_id: revision.job_ids.first).count
          break if count > 0
          sleep 0.1
        end
      end
      log = Job::Log.where(site_id: site.id, job_id: revision.job_ids.first).first
      expect(log).not_to be_nil
    end
  end
end
