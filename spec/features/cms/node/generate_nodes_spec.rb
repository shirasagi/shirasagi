require 'spec_helper'

describe "cms_generate_nodes", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:index_path) { node_generate_nodes_path site.id, node }

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

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#run" do
      # see: https://github.com/shirasagi/shirasagi/issues/272
      start_at = Time.zone.now
      visit index_path
      expect(status_code).to eq 200
      within "form#task-form" do
        click_button I18n.t("views.button.run")
      end
      # task should be started within a minute.
      Timeout.timeout(60) do
        loop do
          task = Cms::Task.where(name: "cms:generate_nodes", site_id: site.id, node_id: node.id).first
          break if task.state != "ready"
          sleep 0.1
        end
      end
      task = Cms::Task.where(name: "cms:generate_nodes", site_id: site.id, node_id: node.id).first
      expect(task.started).to be >= start_at if task.state != "stop"
      expect(task.state).to satisfy { |v| %w(running stop).include?(v) }
    end
  end
end
