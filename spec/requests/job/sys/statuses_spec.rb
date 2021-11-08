require 'spec_helper'

describe Job::Sys::StatusesController, type: :request, dbscope: :example do
  let!(:user) { sys_user }

  before do
    get sns_auth_token_path(format: :json)
    auth_token = JSON.parse(response.body)["auth_token"]

    # login
    params = {
      'authenticity_token' => auth_token,
      'item[email]' => user.email,
      'item[password]' => user.in_password
    }
    post sns_login_path(format: :json), params: params
  end

  context "without service task and without any tasks" do
    it do
      get job_sys_status_path(format: "json")

      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json["notice"]).to be_blank
      expect(json["active_job"]["queue_adapter"]).to eq Rails.application.config.active_job.queue_adapter.to_s
      expect(json["job"]["mode"]).to eq Job::Service.config.mode
      expect(json["job"]["polling_queues"]).to eq Job::Service.config.polling.queues
      expect(json["item"]).to be_blank
    end
  end

  context "with service task and with non-stucked tasks" do
    let!(:service) { Job::Service.create!(name: Job::Service.config.name, current_count: rand(10..20)) }
    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:non_stucked_task) { Job::Task.create!(at: now - 5.hours) }

    it do
      get job_sys_status_path(format: "json")

      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json["notice"]).to be_blank
      expect(json["active_job"]["queue_adapter"]).to eq Rails.application.config.active_job.queue_adapter.to_s
      expect(json["job"]["mode"]).to eq Job::Service.config.mode
      expect(json["job"]["polling_queues"]).to eq Job::Service.config.polling.queues
      expect(json["item"]["name"]).to eq service.name
      expect(json["item"]["current_count"]).to eq service.current_count
      expect(json["item"]["updated"]).to be_present
    end
  end

  context "with service task and with stucked tasks" do
    let!(:service) { Job::Service.create!(name: Job::Service.config.name, current_count: rand(10..20)) }
    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:stucked_task) { Job::Task.create!(at: now - 6.hours) }

    it do
      get job_sys_status_path(format: "json")

      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json["notice"]["notices"]).to eq I18n.t('job.job_stucked.notice')
      expect(json["active_job"]["queue_adapter"]).to eq Rails.application.config.active_job.queue_adapter.to_s
      expect(json["job"]["mode"]).to eq Job::Service.config.mode
      expect(json["job"]["polling_queues"]).to eq Job::Service.config.polling.queues
      expect(json["item"]["name"]).to eq service.name
      expect(json["item"]["current_count"]).to eq service.current_count
      expect(json["item"]["updated"]).to be_present
    end
  end
end
