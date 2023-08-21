require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }

  before { login_gws_user }

  context 'when star is set on index' do
    it do
      expect(memo.star?(gws_user)).to be_falsey

      visit gws_memo_messages_path(site)
      first(".list-item .icon-star.off a").click
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_star'))
      end

      expect(page).to have_css(".list-item .icon-star.on")
      memo.reload
      expect(memo.star?(gws_user)).to be_truthy
    end
  end

  context 'when star is unset on index' do
    it do
      memo.set_star(gws_user).save!
      expect(memo.star?(gws_user)).to be_truthy

      visit gws_memo_messages_path(site)
      first(".list-item .icon-star.on a").click
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.unset_star'))
      end

      expect(page).to have_css(".list-item .icon-star.off")
      memo.reload
      expect(memo.star?(gws_user)).to be_falsey
    end
  end

  context 'when star is set to all selected mails on index' do
    it do
      expect(memo.star?(gws_user)).to be_falsey

      visit gws_memo_messages_path(site)
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        click_on I18n.t('gws/memo/message.links.etc')
        page.accept_confirm do
          click_on I18n.t('gws/memo/message.links.set_star')
        end
      end

      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_star'))
      end

      expect(page).to have_css(".list-item .icon-star.on")
      memo.reload
      expect(memo.star?(gws_user)).to be_truthy
    end
  end

  context 'when star is unset to all selected mails on index' do
    it do
      memo.set_star(gws_user).save!
      expect(memo.star?(gws_user)).to be_truthy

      visit gws_memo_messages_path(site)
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        click_on I18n.t('gws/memo/message.links.etc')
        page.accept_confirm do
          click_on I18n.t('gws/memo/message.links.unset_star')
        end
      end

      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.unset_star'))
      end

      expect(page).to have_css(".list-item .icon-star.off")
      memo.reload
      expect(memo.star?(gws_user)).to be_falsey
    end
  end

  context 'when star is set on show' do
    it do
      expect(memo.star?(gws_user)).to be_falsey

      visit gws_memo_messages_path(site)
      click_on memo.name
      wait_for_js_ready
      within ".addon-view.gws-memo .icon-star" do
        click_on "star"
      end
      wait_for_notice I18n.t('ss.notice.set_star')

      expect(page).to have_css(".addon-view.gws-memo .icon-star.on")
      memo.reload
      expect(memo.star?(gws_user)).to be_truthy
    end
  end

  context 'when star is unset on show' do
    it do
      memo.set_star(gws_user).save!
      expect(memo.star?(gws_user)).to be_truthy

      visit gws_memo_messages_path(site)
      click_on memo.name
      wait_for_js_ready
      within ".addon-view.gws-memo .icon-star" do
        click_on "star"
      end
      wait_for_notice I18n.t('ss.notice.unset_star')

      expect(page).to have_css(".addon-view.gws-memo .icon-star.off")
      memo.reload
      expect(memo.star?(gws_user)).to be_falsey
    end
  end
end
