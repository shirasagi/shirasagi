require 'spec_helper'

describe "opendata_areas", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:parent_node) { create :cms_node_node }

  context "without auth" do
    let(:node) { create :opendata_node_area, cur_node: parent_node }

    it "without login" do
      visit opendata_areas_path(site, node)
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      login_ss_user
      visit opendata_areas_path(site, node)
      expect(page).to have_title('403 Forbidden')
    end
  end

  context "basic crud" do
    let(:name) { unique_id }
    let(:basename) { unique_id }
    let(:keywords) { [ unique_id, unique_id ] }

    before { login_cms_user }

    it do
      expect(Opendata::Node::Area.count).to eq 0

      # create
      visit node_nodes_path(site, parent_node)
      click_on I18n.t('ss.links.new')
      click_on I18n.t('ss.links.change')
      within 'article.mod-opendata' do
        click_on I18n.t('cms.nodes.opendata/area')
      end
      fill_in 'item[name]', with: name
      fill_in 'item[basename]', with: basename
      click_on I18n.t('ss.buttons.save')

      expect(Opendata::Node::Area.count).to eq 1
      Opendata::Node::Area.first.tap do |node|
        expect(node.name).to eq name
        expect(node.filename).to end_with basename
        expect(node.keywords).to eq []
      end

      # read
      click_on I18n.t('ss.links.back_to_index')
      within '.list-items' do
        click_on name
      end
      click_on I18n.t('cms.node_config')

      # update
      click_on I18n.t('ss.links.edit')
      find('#addon-cms-agents-addons-meta .toggle-head h2').click
      fill_in 'item[keywords]', with: keywords.join(' ')
      click_on I18n.t('ss.buttons.save')
      Opendata::Node::Area.first.tap do |node|
        expect(node.name).to eq name
        expect(node.filename).to end_with basename
        expect(node.keywords).to eq keywords
      end

      # delete
      click_on I18n.t('cms.node_config')
      click_on I18n.t('ss.links.delete')
      click_on I18n.t('ss.buttons.delete')
      wait_for_ajax
      expect(Opendata::Node::Area.count).to eq 0
    end
  end
end
