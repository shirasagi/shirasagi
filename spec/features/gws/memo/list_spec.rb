require 'spec_helper'

describe 'gws_memo_lists', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:name1) { "name-#{unique_id}" }
  let(:name2) { "name-#{unique_id}" }
  let!(:category) { create(:gws_memo_category) }

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
          wait_cbox_open do
            click_on I18n.t('ss.apis.users.index')
          end
        end
      end

      within_cbox do
        wait_cbox_close do
          click_on gws_user.name
        end
      end

      within 'form#item-form' do
        within '#addon-gws-agents-addons-member' do
          expect(page).to have_css(".ajax-selected", text: gws_user.name)
        end
        within "#addon-basic" do
          wait_cbox_open do
            click_on I18n.t('gws.apis.categories.index')
          end
        end
      end

      within_cbox do
        wait_event_to_fire("cbox_complete") do
          fill_in 's[keyword]', with: category.name
          click_on I18n.t('ss.buttons.search')
        end
        wait_cbox_close do
          click_on category.name
        end
      end

      within 'form#item-form' do
        within "#addon-basic" do
          expect(page).to have_css(".ajax-selected", text: category.name)
        end
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

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
      wait_for_notice I18n.t('ss.notice.saved')

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
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::Memo::List.all.count).to eq 0
    end
  end
end
