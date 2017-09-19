require 'spec_helper'

describe "jmaxml/action/switch_urgencies", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:node) { create :rss_node_weather_xml, cur_site: site }
  let(:index_path) { jmaxml_action_bases_path(site, node) }

  context "basic crud" do
    let!(:urgency_node) { create :urgency_node_layout, cur_site: site }
    let!(:layout1) { create_cms_layout(cur_node: urgency_node) }
    let!(:layout2) { create_cms_layout(cur_node: urgency_node) }
    let(:model) { Jmaxml::Action::SwitchUrgency }
    let(:name1) { unique_id }
    let(:name2) { unique_id }

    before do
      urgency_node.urgency_default_layout_id = layout1.id
      urgency_node.save!

      login_cms_user
    end

    it do
      #
      # create
      #
      visit index_path
      click_on I18n.t('ss.links.new')

      within 'form' do
        select model.model_name.human, from: 'item[in_type]'
        click_on I18n.t('ss.buttons.new')
      end

      within 'form' do
        fill_in 'item[name]', with: name1
        click_on I18n.t('urgency.apis.layouts.index')
      end
      within '.items' do
        click_on layout2.name
      end
      within 'form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      expect(model.count).to eq 1
      model.first.tap do |action|
        expect(action.name).to eq name1
        expect(action.urgency_layout_id).to eq layout2.id
      end

      #
      # update
      #
      visit index_path
      click_on name1
      click_on I18n.t('ss.links.edit')

      within 'form' do
        fill_in 'item[name]', with: name2
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      expect(model.count).to eq 1
      model.first.tap do |action|
        expect(action.name).to eq name2
        expect(action.urgency_layout_id).to eq layout2.id
      end

      #
      # delete
      #
      visit index_path
      click_on name2
      click_on I18n.t('ss.links.delete')

      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      expect(model.count).to eq 0
    end
  end
end
