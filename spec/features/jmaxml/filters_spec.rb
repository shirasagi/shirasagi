require 'spec_helper'

describe "jmaxml/filters", dbscope: :example do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:node) { create :rss_node_weather_xml, cur_site: site }
  let(:show_path) { node_conf_path(site, node) }

  context "basic crud" do
    let(:name1) { unique_id }
    let(:name2) { unique_id }
    let(:article_node) { create(:article_node_page) }
    let(:category_node) { create(:category_node_page, cur_node: article_node) }
    let(:group1) { create(:cms_group, name: "#{group.name}/#{unique_id}") }
    let(:user1) { create(:cms_test_user, group_ids: [ group1.id ]) }
    let!(:trigger) { create(:jmaxml_trigger_quake_intensity_flash) }
    let!(:action1) { create(:jmaxml_action_publish_page, publish_to_id: article_node.id, category_ids: [ category_node.id ]) }
    let!(:action2) { create(:jmaxml_action_send_mail, recipient_user_ids: [ user1.id ]) }

    before { login_cms_user }

    it do
      #
      # create
      #
      visit show_path
      click_on I18n.t('jmaxml.manage_filter')
      click_on I18n.t('views.links.new')

      within 'form' do
        fill_in 'item[name]', with: name1
        select trigger.name, from: 'item_trigger_ids_0'
        select action1.name, from: 'item_action_ids_0'
        select action2.name, from: 'item_action_ids_1'
        click_on I18n.t('views.button.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      node.reload
      expect(node.filters.count).to eq 1
      node.filters.first.tap do |region|
        expect(region.name).to eq name1
        expect(region.trigger_ids).to eq [ trigger.id.to_s ]
        expect(region.action_ids).to eq [ action1.id.to_s, action2.id.to_s ]
      end

      #
      # update
      #
      visit show_path
      click_on I18n.t('jmaxml.manage_filter')
      click_on name1
      click_on I18n.t('views.links.edit')

      within 'form' do
        fill_in 'item[name]', with: name2
        click_on I18n.t('views.button.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      node.reload
      expect(node.filters.count).to eq 1
      node.filters.first.tap do |region|
        expect(region.name).to eq name2
        expect(region.trigger_ids).to eq [ trigger.id.to_s ]
        expect(region.action_ids).to eq [ action1.id.to_s, action2.id.to_s ]
      end

      #
      # delete
      #
      visit show_path
      click_on I18n.t('jmaxml.manage_filter')
      click_on name2
      click_on I18n.t('views.links.delete')

      within 'form' do
        click_on I18n.t('views.button.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      node.reload
      expect(node.filters.count).to eq 0
    end
  end
end
