require 'spec_helper'

describe "node_generate_nodes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :cms_node }

  let(:index_path) { node_generate_nodes_path site.id, node }

  def find_task
    Cms::Task.site(site).where(name: "cms:generate_nodes", node_id: node.id, segment: nil).first
  end

  context "without segments" do
    let(:segments) { [] }

    before do
      @save_generate_segments = SS.config.cms.generate_segments
      SS.config.replace_value_at(:cms, :generate_segments, { "node" => { site.host => segments } })
    end

    after do
      SS.config.replace_value_at(:cms, :generate_segments, @save_generate_segments)
    end

    it "#index" do
      login_cms_user
      visit index_path
      expect(current_path).to eq index_path

      task = find_task
      expect(task.state).to eq "stop"

      # run
      within "form#task-form" do
        click_button I18n.t("ss.buttons.run")
      end
      expect(current_path).to eq index_path
      wait_for_notice I18n.t('ss.tasks.started')

      task = find_task
      expect(task.state).to eq "ready"
    end
  end

  context "with segments" do
    let(:segments) { %w(web01 web02 web03) }

    before do
      @save_generate_segments = SS.config.cms.generate_segments
      SS.config.replace_value_at(:cms, :generate_segments, { "node" => { site.host => segments } })
    end

    after do
      SS.config.replace_value_at(:cms, :generate_segments, @save_generate_segments)
    end

    it "#index" do
      login_cms_user
      visit index_path

      expect(current_path).to eq index_path

      task = find_task
      expect(task.state).to eq "stop"

      # run
      within "form#task-form" do
        click_button I18n.t("ss.buttons.run")
      end
      expect(current_path).to eq index_path
      wait_for_notice I18n.t('ss.tasks.started')

      task = find_task
      expect(task.state).to eq "ready"
    end
  end
end
