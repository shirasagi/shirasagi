require 'spec_helper'

describe 'gws_memo_list_messages', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:sender) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let!(:recipient) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let!(:list) { create(:gws_memo_list, cur_site: site, member_ids: [sender.id, recipient.id]) }
  let!(:list_memo) { create(:gws_memo_list_message, cur_user: user, cur_site: site, list: list, state: 'public') }
  let(:seen_at) { Time.zone.now.beginning_of_minute }

  before { login_gws_user }

  describe "seen" do
    before do
      expect(list_memo.user_settings).to be_present

      Timecop.freeze(seen_at) do
        list_memo.set_seen(sender).save!
      end
      list_memo.reload
    end

    it do
      visit gws_memo_lists_path(site: site)
      click_on list.name
      click_on list_memo.name
      click_on I18n.t("gws/memo.buttons.seen")

      within "tr[data-id='#{sender.id}']" do
        expect(page).to have_content(sender.long_name)
        expect(page).to have_content(I18n.l(seen_at, format: :picker))
      end
      within "tr[data-id='#{recipient.id}']" do
        expect(page).to have_content(recipient.long_name)
        expect(page).to have_content(I18n.t('gws/memo.unseen'))
      end

      within "form.index-search" do
        fill_in "s[keyword]", with: sender.name
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_css("tr[data-id='#{recipient.id}']")
    end
  end
end
