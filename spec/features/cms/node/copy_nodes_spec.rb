require 'spec_helper'

describe "cms_copy_nodes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :cms_node }

  let(:index_path) { node_copy_path site.id, node.id }

  context 'run copy nodes' do
    let(:target_node_name) { unique_id }
    let(:target_node_filename) { unique_id }

    before do
      login_cms_user
    end

    it 'redirect index_path and notice text' do
      visit index_path

      fill_in 'item[target_node_name]', with: target_node_name
      fill_in 'item[target_node_filename]', with: target_node_filename
      click_on I18n.t('ss.buttons.run')
      expect(current_path).to eq index_path
      wait_for_notice I18n.t('cms.copy_nodes.started_job'), wait: 60
      expect(Cms::CopyNodesTask.first.target_node_name).to eq target_node_name
      expect(Cms::CopyNodesTask.first.target_node_filename).to eq target_node_filename
      expect(enqueued_jobs.first[:job]).to eq Cms::Node::CopyNodesJob
    end

    it 'invalid without target_node_name' do
      visit index_path

      fill_in 'item[target_node_name]', with: ''
      fill_in 'item[target_node_filename]', with: target_node_filename
      click_on I18n.t('ss.buttons.run')
      message = Cms::CopyNodesTask.t(:target_node_name) + I18n.t('errors.messages.blank')
      expect(page).to have_css('.errorExplanation', text: message)
    end

    it 'invalid without target_node_filename' do
      visit index_path

      fill_in 'item[target_node_name]', with: target_node_name
      fill_in 'item[target_node_filename]', with: ''
      click_on I18n.t('ss.buttons.run')
      message = Cms::CopyNodesTask.t(:target_node_filename) + I18n.t('errors.messages.blank')
      expect(page).to have_css('.errorExplanation', text: message)
    end

    it 'invalid without existing parent node' do
      visit index_path

      fill_in 'item[target_node_name]', with: target_node_name
      fill_in 'item[target_node_filename]', with: "parent/#{target_node_filename}"
      click_on I18n.t('ss.buttons.run')
      message = Cms::CopyNodesTask.t(:target_node_filename) + I18n.t('errors.messages.not_found_parent_nodes', name: 'parent')
      expect(page).to have_css('.errorExplanation', text: message)
    end

    it 'cancel copy_node' do
      visit index_path

      click_on I18n.t('ss.buttons.cancel')
      expect(current_path).to eq node_conf_path(site: site.id, cid: node.id)
    end
  end
end
