require 'spec_helper'

describe "cms_copy_nodes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :cms_node }

  let(:index_path) { node_copy_path site.id, node.id }

  context 'run copy nodes' do
    let(:target_node_name) { ss_japanese_text }
    let(:target_node_filename) { unique_id }

    before do
      login_cms_user
    end

    it 'redirect index_path and notice text' do
      visit index_path

      within "form#item-form" do
        fill_in 'item[target_node_name]', with: target_node_name
        fill_in 'item[target_node_filename]', with: target_node_filename
        click_on I18n.t('ss.buttons.run')
      end
      wait_for_notice I18n.t('cms.copy_nodes.started_job'), wait: 60
      expect(current_path).to eq index_path

      expect(Cms::CopyNodesTask.all.count).to eq 1
      Cms::CopyNodesTask.all.first.tap do |task|
        expect(task.target_node_name).to eq target_node_name
        expect(task.target_node_filename).to eq target_node_filename
      end
      enqueued_jobs.first.tap do |enqueued_job|
        expect(enqueued_job[:job]).to eq Cms::Node::CopyNodesJob
        expect(enqueued_job[:args]).to have(1).items
        enqueued_job[:args].tap do |args|
          options = args.extract_options!
          options = options.with_indifferent_access
          expect(options[:target_node_name]).to eq target_node_name
          expect(options[:target_node_filename]).to eq target_node_filename
        end
      end
    end

    it 'invalid without target_node_name' do
      visit index_path

      within "form#item-form" do
        fill_in 'item[target_node_name]', with: ''
        fill_in 'item[target_node_filename]', with: target_node_filename
        click_on I18n.t('ss.buttons.run')
      end
      message = Cms::CopyNodesTask.t(:target_node_name) + I18n.t('errors.messages.blank')
      wait_for_error message
    end

    it 'invalid without target_node_filename' do
      visit index_path

      within "form#item-form" do
        fill_in 'item[target_node_name]', with: target_node_name
        fill_in 'item[target_node_filename]', with: ''
        click_on I18n.t('ss.buttons.run')
      end
      message = Cms::CopyNodesTask.t(:target_node_filename) + I18n.t('errors.messages.blank')
      wait_for_error message
    end

    it 'invalid without existing parent node' do
      visit index_path

      within "form#item-form" do
        fill_in 'item[target_node_name]', with: target_node_name
        fill_in 'item[target_node_filename]', with: "parent/#{target_node_filename}"
        click_on I18n.t('ss.buttons.run')
      end
      message = Cms::CopyNodesTask.t(:target_node_filename) + I18n.t('errors.messages.not_found_parent_nodes', name: 'parent')
      wait_for_error message
    end

    it 'cancel copy_node' do
      visit index_path

      within "form#item-form" do
        click_on I18n.t('ss.buttons.cancel')
      end
      expect(current_path).to eq node_conf_path(site: site.id, cid: node.id)
    end
  end
end
