require 'spec_helper'

describe "sns/apis/file_gen_tasks", type: :request, dbscope: :example do
  let!(:user) { create :sys_user_sample }
  let!(:task) do
    task = SS::FileGenTask.new(user: user)
    task.name = "#{unique_id}_#{user.id}_#{Time.zone.now.to_i}"
    task.state = state
    task.file_basename = unique_id
    task.file_format = "csv"
    task.save!

    task
  end

  context "usual case" do
    let(:state) { SS::FileGenTask::STATE_COMPLETED }

    before do
      task.generated_file_path.tap do |generated_file_path|
        FileUtils.mkdir_p(File.dirname(generated_file_path))
        FileUtils.cp("#{Rails.root}/spec/fixtures/sys/postal_code.csv", generated_file_path)
      end
    end

    it do
      login_params = {
        item: {
          email: user.email,
          password: SS::Crypto.encrypt(ss_pass, type: "AES-256-CBC"),
          encryption_type: "AES-256-CBC"
        }
      }
      post sns_login_path(format: :json), params: login_params

      get sns_apis_file_gen_task_download_path(id: task)
      expect(response.status).to eq 200
      expect(response.media_type).to eq "text/csv"
      expect(response.headers["Content-Disposition"]).to include(task.file_basename, ".#{task.file_format}")
      expect(response.body).to eq File.binread("#{Rails.root}/spec/fixtures/sys/postal_code.csv")
    end
  end

  context "other users'" do
    let!(:user2) { create :sys_user_sample }
    let(:state) { SS::FileGenTask::STATE_COMPLETED }

    it do
      login_params = {
        item: {
          email: user2.email,
          password: SS::Crypto.encrypt(ss_pass, type: "AES-256-CBC"),
          encryption_type: "AES-256-CBC"
        }
      }
      post sns_login_path(format: :json), params: login_params

      get sns_apis_file_gen_task_download_path(id: task)
      expect(response.status).to eq 404
    end
  end

  context "when state is 'stop'" do
    let(:state) { SS::FileGenTask::STATE_STOP }

    it do
      login_params = {
        item: {
          email: user.email,
          password: SS::Crypto.encrypt(ss_pass, type: "AES-256-CBC"),
          encryption_type: "AES-256-CBC"
        }
      }
      post sns_login_path(format: :json), params: login_params

      get sns_apis_file_gen_task_download_path(id: task)
      expect(response.status).to eq 404
    end
  end

  context "when state is 'ready'" do
    let(:state) { SS::FileGenTask::STATE_READY }

    it do
      login_params = {
        item: {
          email: user.email,
          password: SS::Crypto.encrypt(ss_pass, type: "AES-256-CBC"),
          encryption_type: "AES-256-CBC"
        }
      }
      post sns_login_path(format: :json), params: login_params

      get sns_apis_file_gen_task_download_path(id: task)
      expect(response.status).to eq 404
    end
  end

  context "when state is 'running'" do
    let(:state) { SS::FileGenTask::STATE_RUNNING }

    it do
      login_params = {
        item: {
          email: user.email,
          password: SS::Crypto.encrypt(ss_pass, type: "AES-256-CBC"),
          encryption_type: "AES-256-CBC"
        }
      }
      post sns_login_path(format: :json), params: login_params

      get sns_apis_file_gen_task_download_path(id: task)
      expect(response.status).to eq 404
    end
  end

  context "when state is 'failed'" do
    let(:state) { SS::FileGenTask::STATE_FAILED }

    it do
      login_params = {
        item: {
          email: user.email,
          password: SS::Crypto.encrypt(ss_pass, type: "AES-256-CBC"),
          encryption_type: "AES-256-CBC"
        }
      }
      post sns_login_path(format: :json), params: login_params

      get sns_apis_file_gen_task_download_path(id: task)
      expect(response.status).to eq 404
    end
  end

  context "when state is 'interrupted'" do
    let(:state) { SS::FileGenTask::STATE_INTERRUPTED }

    it do
      login_params = {
        item: {
          email: user.email,
          password: SS::Crypto.encrypt(ss_pass, type: "AES-256-CBC"),
          encryption_type: "AES-256-CBC"
        }
      }
      post sns_login_path(format: :json), params: login_params

      get sns_apis_file_gen_task_download_path(id: task)
      expect(response.status).to eq 404
    end
  end

  context "when state is 'completed' but file is not generated" do
    let(:state) { SS::FileGenTask::STATE_COMPLETED }

    it do
      login_params = {
        item: {
          email: user.email,
          password: SS::Crypto.encrypt(ss_pass, type: "AES-256-CBC"),
          encryption_type: "AES-256-CBC"
        }
      }
      post sns_login_path(format: :json), params: login_params

      get sns_apis_file_gen_task_download_path(id: task)
      expect(response.status).to eq 404
    end
  end
end
