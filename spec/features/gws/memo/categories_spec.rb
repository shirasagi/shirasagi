require 'spec_helper'

describe 'gws_memo_categories', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:name1) { "name-#{unique_id}" }
  let(:name2) { "name-#{unique_id}" }

  context 'without login' do
    it do
      visit gws_memo_categories_path(site: site)
      expect(current_path).to eq sns_login_path
    end
  end

  context 'basic crud' do
    before { login_gws_user }

    it do
      # create
      visit gws_memo_categories_path(site: site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[name]', with: "#{name1}/#{name2}/#{name2}"
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_content(I18n.t('mongoid.errors.models.gws/memo/category.too_deep', max: 2))
      expect(page).to have_content(I18n.t('mongoid.errors.models.gws/memo/category.not_found_parent'))

      within 'form#item-form' do
        fill_in 'item[name]', with: name1
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Memo::Category.all.count).to eq 1
      Gws::Memo::Category.all.first.tap do |list|
        expect(list.name).to eq name1
      end

      # update
      visit gws_memo_categories_path(site: site)
      fill_in 's[keyword]', with: name1
      click_on I18n.t('ss.buttons.search')
      wait_for_js_ready
      find('.list-item .info .meta .datetime').click
      within ".tap-menu" do
        click_on I18n.t('ss.links.edit')
      end
      within 'form#item-form' do
        fill_in 'item[name]', with: name2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Memo::Category.all.count).to eq 1
      Gws::Memo::Category.all.first.tap do |list|
        expect(list.name).to eq name2
      end

      # delete
      visit gws_memo_categories_path(site: site)
      find('.list-item .info').click
      within '.list-item .tap-menu' do
        click_on I18n.t('ss.links.delete')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::Memo::Category.all.count).to eq 0
    end
  end
end
