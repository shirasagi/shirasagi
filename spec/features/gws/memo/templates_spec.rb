require 'spec_helper'

describe 'gws_memo_templates', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:name1) { "name-#{unique_id}" }
  let(:name2) { "name-#{unique_id}" }

  context 'without login' do
    it do
      visit gws_memo_templates_path(site: site)
      expect(current_path).to eq sns_login_path
    end
  end

  context 'basic crud' do
    before { login_gws_user }

    it do
      # create
      visit gws_memo_templates_path(site: site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[name]', with: name1
        fill_in 'item[text]', with: name1
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Memo::Template.all.count).to eq 1
      Gws::Memo::Template.all.first.tap do |template|
        expect(template.name).to eq name1
      end

      # update
      visit gws_memo_templates_path(site: site)
      fill_in 's[keyword]', with: name1
      click_on I18n.t('ss.buttons.search')
      find('.list-item .info').click
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        fill_in 'item[name]', with: name2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Memo::Template.all.count).to eq 1
      Gws::Memo::Template.all.first.tap do |template|
        expect(template.name).to eq name2
      end

      # delete
      visit gws_memo_templates_path(site: site)
      find('.list-item .info').click
      within '.list-item .tap-menu' do
        click_on I18n.t('ss.links.delete')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::Memo::Template.all.count).to eq 0
    end
  end
end
