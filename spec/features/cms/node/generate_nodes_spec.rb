require 'spec_helper'

describe "cms_generate_nodes" do
  subject(:site) { cms_site }
  subject(:node) { create_once :cms_node_page, name: "cms" }
  subject(:index_path) { node_generate_nodes_path site.host, node }

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

    it "#run" do
      # see: https://github.com/shirasagi/shirasagi/issues/272
      start_at = Time.zone.now
      visit index_path
      expect(status_code).to eq 200
      within "form#task-form" do
        click_button "Run"
      end
      # task should be started within a minute.
      timeout(60) do
        loop do
          task = Cms::Task.where(name: "cms:generate_nodes", site_id: site.id, node_id: node.id).first
          break if task.state != "ready"
          sleep 0.1
        end
      end
      task = Cms::Task.where(name: "cms:generate_nodes", site_id: site.id, node_id: node.id).first
      expect(task.started).to be >= start_at if task.state != "stop"
      expect(task.state).to satisfy { |v| ["running", "stop"].include?(v) }
    end
  end
end
