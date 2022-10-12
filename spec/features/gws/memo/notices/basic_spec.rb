require 'spec_helper'

describe 'gws/memo/notices', type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let(:circular_item) { create(:gws_circular_post, :gws_circular_posts) }
    let(:circular_path) { gws_circular_post_path(site: site, category: '-', id: circular_item) }
    let!(:item_old) do
      SS::Notification.create!(
        cur_group: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "text-#{unique_id}" * 10,
        member_ids: [user.id], state: "public"
      )
    end
    let!(:item_new) do
      SS::Notification.create!(
        cur_group: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "", url: circular_path,
        member_ids: [user.id], state: "public"
      )
    end
    let!(:item_no_info) do
      SS::Notification.create!(
        cur_group: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "",
        member_ids: [user.id], state: "public"
      )
    end

    before { login_gws_user }

    it do
      visit gws_memo_notices_path(site: site)
      expect(page).to have_css('li.list-item', count: 3)

      click_link item_old.name
      expect(current_path).to eq gws_memo_notice_path(site: site, id: item_old.id)

      click_link I18n.t('ss.links.back_to_index')
      click_link item_new.name
      expect(current_path).to eq circular_path

      visit gws_memo_notices_path(site: site)
      click_link item_no_info.name
      expect(current_path).to eq gws_memo_notices_path(site: site)

      visit delete_gws_memo_notice_path(site: site, id: item_old.id)
      within 'form' do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('li.list-item', count: 2)

      first("input[value='#{item_new.id}']").click
      page.accept_confirm do
        within ".list-head" do
          click_button I18n.t('ss.links.delete')
        end
      end
      expect(page).to have_css('li.list-item', count: 1)

      visit File.join(gws_memo_notices_path(site: site), 'latest', 'all')
      expect(page).to have_content(item_no_info.name)

      visit File.join(gws_memo_notices_path(site: site), 'latest', 'unseen')
      expect(page).to have_no_content(item_no_info.name)
    end
  end
end
