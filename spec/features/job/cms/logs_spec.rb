require 'spec_helper'
require "csv"

describe "job_cms_logs", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { job_cms_logs_path site.id }
  let(:job) { create(:job_model, cur_site: site) }
  let(:log1) { create(:job_log, :job_log_running, job: job) }
  let(:log2) { create(:job_log, :job_log_completed, job: job) }
  let(:log3) { create(:job_log, :job_log_failed, job: job) }
  let(:logs) { [log1, log2, log3] }

  before do
    logs.each do |log|
      FileUtils.mkdir_p(File.dirname(log.file_path)) rescue nil
      File.open(log.file_path, 'wt') do |f|
        f.puts unique_id
      end
    end
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#download" do
      visit index_path
      click_on I18n.t('ss.links.download')
      expect(status_code).to eq 200

      within "form" do
        click_button I18n.t("ss.download")
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
      expect(Job::Log.count).to be > 0

      visit index_path
      click_on I18n.t('ss.links.delete')
      expect(status_code).to eq 200

      within "form" do
        select I18n.t("history.options.duration.all_delete"), from: "item_save_term"
        click_button I18n.t("ss.buttons.delete")
      end
      expect(status_code).to eq 200
      expect(Job::Log.count).to eq 0

      # log files should be removed
      expect(File.exist?(log1.file_path)).to be_falsey
      expect(File.exist?(log2.file_path)).to be_falsey
      expect(File.exist?(log3.file_path)).to be_falsey
    end

    context 'when ymd is present' do
      before do
        log2.set(updated: log2.updated - 1.day, created: log2.created - 1.day)
        log3.set(updated: log3.updated - 2.days, created: log3.created - 2.days)
      end

      it "#download" do
        visit job_cms_daily_logs_path(site.id, ymd: Time.zone.now.to_date.strftime('%Y%m%d'))
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        within "form" do
          click_button I18n.t("ss.download")
        end

        expect(status_code).to eq 200
        csv_lines = CSV.parse(page.html.encode("UTF-8"))
        expect(csv_lines.length).to eq 2
        expect(csv_lines[0]).to eq %w(ClassName Started Closed State Args Logs)
        expect(csv_lines[1]).to include(logs[0].class_name)
        expect(csv_lines[1]).to include(logs[0].start_label)
        expect(csv_lines[1]).to include(I18n.t(logs[0].state, scope: "job.state"))

        visit job_cms_daily_logs_path(site.id, ymd: Time.zone.now.to_date.strftime('%Y%m%d'))
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        within "form" do
          select I18n.t('job.save_term.all_save')
          click_button I18n.t("ss.download")
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

        visit job_cms_daily_logs_path(site.id, ymd: Time.zone.now.to_date.yesterday.yesterday.strftime('%Y%m%d'))
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        within "form" do
          click_button I18n.t("ss.download")
        end

        # 表示している日時によらず、常に現在日〜1日前のログがダウンロードされる
        expect(status_code).to eq 200
        csv_lines = CSV.parse(page.html.encode("UTF-8"))
        expect(csv_lines.length).to eq 2
        expect(csv_lines[0]).to eq %w(ClassName Started Closed State Args Logs)
        expect(csv_lines[1]).to include(logs[0].class_name)
        expect(csv_lines[1]).to include(logs[0].start_label)
        expect(csv_lines[1]).to include(logs[0].closed_label)
        expect(csv_lines[1]).to include(I18n.t(logs[0].state, scope: "job.state"))

        visit job_cms_daily_logs_path(site.id, ymd: Time.zone.now.to_date.yesterday.yesterday.strftime('%Y%m%d'))
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        within "form" do
          select I18n.t('job.save_term.all_save')
          click_button I18n.t("ss.download")
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
    end
  end
end
