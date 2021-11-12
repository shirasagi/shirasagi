require 'spec_helper'
require "csv"

describe "job_sys_statuses", type: :feature, dbscope: :example do
  before { login_sys_user }

  context "without service task and without any tasks" do
    it do
      visit job_sys_status_path

      within "#addon-basic" do
        expect(page).to have_css(".see", text: Rails.application.config.active_job.queue_adapter)
        expect(page).to have_css(".see", text: Job::Service.config.mode)
        expect(page).to have_css(".see", text: Job::Service.config.polling.queues.join(", "))
      end
    end
  end

  context "with service task and with non-stucked tasks" do
    let!(:service) { Job::Service.create!(name: Job::Service.config.name, current_count: rand(10..20)) }
    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:non_stucked_task1) { Job::Task.create!(at: now - 1.minute) }
    let!(:non_stucked_task2) { Job::Task.create!(at: now - 6.hours + 2.minutes) }

    it do
      visit job_sys_status_path

      expect(page).to have_no_css("#errorExplanation")

      within "#addon-basic" do
        expect(page).to have_css(".see", text: Rails.application.config.active_job.queue_adapter)
        expect(page).to have_css(".see", text: Job::Service.config.mode)
        expect(page).to have_css(".see", text: Job::Service.config.polling.queues.join(", "))
        expect(page).to have_css(".see", text: service.name)
        expect(page).to have_css(".see", text: service.current_count)
      end
    end
  end

  context "with service task and with stucked tasks" do
    let!(:service) { Job::Service.create!(name: Job::Service.config.name, current_count: rand(10..20)) }
    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:non_stucked_task1) { Job::Task.create!(at: now - 1.minute) }
    let!(:non_stucked_task2) { Job::Task.create!(at: now - 6.hours + 2.minutes) }
    let!(:stucked_task) { Job::Task.create!(at: now - 6.hours) }

    it do
      visit job_sys_status_path

      within "#errorExplanation" do
        expect(page).to have_css("h2", text: I18n.t("job.job_stucked.header"))
        expect(page).to have_css("p", text: I18n.t('job.job_stucked.body'))
        expect(page).to have_css("li", text: I18n.t('job.job_stucked.notice').first)
      end

      within "#addon-basic" do
        expect(page).to have_css(".see", text: Rails.application.config.active_job.queue_adapter)
        expect(page).to have_css(".see", text: Job::Service.config.mode)
        expect(page).to have_css(".see", text: Job::Service.config.polling.queues.join(", "))
        expect(page).to have_css(".see", text: service.name)
        expect(page).to have_css(".see", text: service.current_count)
      end
    end
  end
end
