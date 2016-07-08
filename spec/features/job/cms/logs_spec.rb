require 'spec_helper'
require "csv"

describe "job_cms_logs", dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { job_cms_logs_path site.id }
  let(:job) { create(:job_model, cur_site: site) }
  let(:log1) { create(:job_log, :job_log_running, job: job) }
  let(:log2) { create(:job_log, :job_log_completed, job: job) }
  let(:log3) { create(:job_log, :job_log_failed, job: job) }
  let(:logs) { [log1, log2, log3] }

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
      # ensure that log is existed
      logs.each do |log|
        expect(log).not_to be_nil
      end

      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#download" do
      # ensure that log is existed
      logs.each do |log|
        expect(log).not_to be_nil
      end

      visit index_path
      click_on 'ダウンロード'
      expect(status_code).to eq 200

      within "form" do
        click_button I18n.t(:download, scope: "views")
      end

      expect(status_code).to eq 200
      csv_lines = CSV.parse(page.html.encode("UTF-8"))
      expect(csv_lines.length).to eq 4
      expect(csv_lines[0]).to eq %w(ClassName Started Closed State Args Logs)
      expect(csv_lines[1]).to include(logs[0].class_name)
      expect(csv_lines[1]).to include(logs[0].start_label)
      expect(csv_lines[1]).to include(I18n.t(logs[0].state, scope: "job.state"))
      expect(csv_lines[2]).to include(logs[1].class_name)
      expect(csv_lines[2]).to include(logs[1].start_label)
      expect(csv_lines[2]).to include(logs[1].closed_label)
      expect(csv_lines[2]).to include(I18n.t(logs[1].state, scope: "job.state"))
      expect(csv_lines[3]).to include(logs[2].class_name)
      expect(csv_lines[3]).to include(logs[2].start_label)
      expect(csv_lines[3]).to include(logs[2].closed_label)
      expect(csv_lines[3]).to include(I18n.t(logs[2].state, scope: "job.state"))
    end

    it "#batch_destroy" do
      # ensure that log is existed
      logs.each do |log|
        expect(log).not_to be_nil
      end
      expect(Job::Log.count).to be > 0

      visit index_path
      click_on '削除する'
      expect(status_code).to eq 200

      within "form" do
        select I18n.t("history.save_term.all_delete"), from: "item_save_term"
        click_button I18n.t("button.delete", scope: "views")
      end
      expect(status_code).to eq 200
      expect(Job::Log.count).to eq 0
    end
  end
end
