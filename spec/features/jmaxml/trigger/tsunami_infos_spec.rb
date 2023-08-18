require 'spec_helper'

describe "jmaxml/trigger/tsunami_infos", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :rss_node_weather_xml, cur_site: site }
  let(:index_path) { jmaxml_trigger_bases_path(site, node) }

  context "basic crud" do
    let!(:region) { create(:jmaxml_tsunami_region_c100) }
    let(:model) { Jmaxml::Trigger::TsunamiInfo }
    let(:name1) { unique_id }
    let(:name2) { unique_id }

    before { login_cms_user }

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
        check 'item_sub_type_special_alert'
        check 'item_sub_type_alert'
        check 'item_sub_type_warning'
        click_on I18n.t('jmaxml.apis.tsunami_regions.index')
      end
      within '.items' do
        click_on region.name
      end
      within 'form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      expect(model.count).to eq 1
      model.first.tap do |trigger|
        expect(trigger.name).to eq name1
        expect(trigger.training_status).to eq 'disabled'
        expect(trigger.test_status).to eq 'disabled'
        expect(trigger.sub_types.select(&:present?).sort).to eq %w(alert special_alert warning)
        expect(trigger.target_region_ids.first).to eq region.id
      end

      #
      # update
      #
      visit index_path
      click_on name1
      click_on I18n.t('ss.links.edit')

      within 'form' do
        fill_in 'item[name]', with: name2
        uncheck 'item_sub_type_warning'
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      expect(model.count).to eq 1
      model.first.tap do |trigger|
        expect(trigger.name).to eq name2
        expect(trigger.training_status).to eq 'disabled'
        expect(trigger.test_status).to eq 'disabled'
        expect(trigger.sub_types.select(&:present?).sort).to eq %w(alert special_alert)
        expect(trigger.target_region_ids.first).to eq region.id
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
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'), wait: 60)

      expect(model.count).to eq 0
    end
  end
end
