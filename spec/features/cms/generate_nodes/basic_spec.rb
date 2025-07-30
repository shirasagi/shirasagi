require 'spec_helper'

describe "cms_generate_nodes", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  before { login_cms_user }

  context "basic" do
    it do
      expect(Cms::Task.all.count).to eq 0

      visit cms_generate_nodes_path(site: site.id)
      expect(page).to have_css(".state", text: I18n.t("job.state.stop"))
      expect(page).to have_css(".count", text: "0")

      expect(Cms::Task.all.count).to eq 1
      Cms::Task.all.first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.node_id).to be_blank
        expect(task.segment).to be_blank
        expect(task.name).to eq "cms:generate_nodes"
        expect(task.state).to eq "stop"
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 0
        expect(task.started).to be_blank
        expect(task.closed).to be_blank
      end

      within "form#task-form" do
        click_on I18n.t("ss.buttons.run")
      end
      wait_for_notice I18n.t("ss.tasks.started")

      expect(enqueued_jobs.length).to eq 1
      enqueued_jobs.first.tap do |enqueued_job|
        expect(enqueued_job[:job]).to eq Cms::Node::GenerateJob
        expect(enqueued_job[:args]).to be_present
      end

      expect(Cms::Task.all.count).to eq 1
      Cms::Task.all.first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.node_id).to be_blank
        expect(task.segment).to be_blank
        expect(task.name).to eq "cms:generate_nodes"
        expect(task.state).to eq "ready"
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 0
        expect(task.started).to be_blank
        expect(task.closed).to be_blank
      end
    end
  end
end
