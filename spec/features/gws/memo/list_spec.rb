require 'spec_helper'

describe 'gws_memo_lists', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:name1) { "name-#{unique_id}" }
  let(:name2) { "name-#{unique_id}" }

  context 'without login' do
    it do
      visit gws_memo_lists_path(site: site)
      expect(current_path).to eq sns_login_path
    end
  end

  context 'basic crud' do
    before { login_gws_user }

    it do
      # create
      visit gws_memo_lists_path(site: site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[name]', with: name1
        within '#addon-gws-agents-addons-member' do
          click_on I18n.t('ss.apis.users.index')
        end
      end

      wait_for_ajax
      within '#cboxLoadedContent' do
        click_on gws_user.name
      end

      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Memo::List.all.count).to eq 1
      Gws::Memo::List.all.first.tap do |list|
        expect(list.name).to eq name1
        expect(list.member_ids).to eq [ gws_user.id ]
      end

      # update
      visit gws_memo_lists_path(site: site)
      find('.list-item .info').click
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        fill_in 'item[name]', with: name2
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Memo::List.all.count).to eq 1
      Gws::Memo::List.all.first.tap do |list|
        expect(list.name).to eq name2
        expect(list.member_ids).to eq [ gws_user.id ]
      end

      # delete
      visit gws_memo_lists_path(site: site)
      find('.list-item .info').click
      within '.list-item .tap-menu' do
        click_on I18n.t('ss.links.delete')
      end
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Memo::List.all.count).to eq 0
    end
  end
end
