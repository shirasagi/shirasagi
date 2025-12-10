require 'spec_helper'

describe "gws_notices_readables", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let(:group) { gws_user.groups.site(site).first }
  let!(:folder) { create(:gws_notice_folder, cur_site: site) }
  let!(:item1) do
    item = Timecop.freeze(now - 3.days) do
      create :gws_notice_post, cur_site: site, folder: folder, state: "closed"
    end

    Timecop.freeze(now - 2.days) do
      item.text = "text-#{unique_id}"
      item.save!
    end

    Timecop.freeze(now - 1.day) do
      item.state = "public"
      item.released = now - 12.hours
      item.release_date = now - 12.hours
      item.save!
    end

    Gws::Notice::Post.find(item.id)
  end
  let!(:item2) do
    item = Timecop.freeze(now - 6.days) do
      create :gws_notice_post, cur_site: site, folder: folder, state: "closed"
    end

    Timecop.freeze(now - 5.days) do
      item.text = "text-#{unique_id}"
      item.save!
    end

    Timecop.freeze(now - 4.day) do
      item.state = "public"
      item.released = now - 3.days - 12.hours
      item.release_date = now - 3.days - 12.hours
      item.close_date = now - 12.hours
      item.save!
    end

    Gws::Notice::Post.find(item.id)
  end
  let!(:item3) do
    item = Timecop.freeze(now - 9.days) do
      create :gws_notice_post, cur_site: site, folder: folder, state: "closed"
    end

    Timecop.freeze(now - 8.days) do
      item.text = "text-#{unique_id}"
      item.save!
    end

    Timecop.freeze(now - 7.day) do
      item.state = "public"
      item.deleted = now - 7.days - 12.hours
      item.save!
    end

    Gws::Notice::Post.find(item.id)
  end
  let!(:user_portal) { create :gws_portal_user_setting, cur_user: user, portal_user: user }
  let!(:user_portlet) do
    create :gws_portal_user_portlet, :gws_portal_notice_portlet, cur_user: user, setting: user_portal
  end
  let!(:group_portal) { create :gws_portal_group_setting, cur_user: user, portal_group: group }
  let!(:group_portlet) do
    create :gws_portal_group_portlet, :gws_portal_notice_portlet, cur_user: user, setting: group_portal
  end
  let!(:site_portal) { create :gws_portal_group_setting, cur_user: user, portal_group: site }
  let!(:site_portlet) do
    create :gws_portal_group_portlet, :gws_portal_notice_portlet, cur_user: user, setting: site_portal
  end

  context "released date should be shown in all user screens" do
    it do
      expect(item1.released).to be_present
      expect(item1.released.in_time_zone).not_to eq item1.updated.in_time_zone
      expect(item1.released.in_time_zone).not_to eq item1.created.in_time_zone
      expect(item1.updated.in_time_zone).not_to eq item1.created.in_time_zone
      expect(item2.released).to be_present
      expect(item2.released.in_time_zone).not_to eq item2.updated.in_time_zone
      expect(item2.released.in_time_zone).not_to eq item2.created.in_time_zone
      expect(item2.updated.in_time_zone).not_to eq item2.created.in_time_zone
      expect(item3.deleted).to be_present
      expect(item3.deleted.in_time_zone).not_to eq item3.updated.in_time_zone

      # ポータル - メイン
      login_user user, to: gws_portal_path(site: site)
      wait_for_all_turbo_frames
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item .datetime", text: I18n.l(item1.released, format: :picker))
      end
      within ".portlets .gws-notices" do
        expect(page).to have_css(".list-item .datetime", text: I18n.l(item1.released, format: :picker))
      end

      # ポータル - 個人
      visit gws_portal_user_path(site: site, user: user)
      wait_for_all_turbo_frames
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item .datetime", text: I18n.l(item1.released, format: :picker))
      end
      within ".portlets .gws-notices" do
        expect(page).to have_css(".list-item .datetime", text: I18n.l(item1.released, format: :picker))
      end

      # ポータル - グループ
      visit gws_portal_group_path(site: site, group: group)
      wait_for_all_turbo_frames
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item .datetime", text: I18n.l(item1.released, format: :picker))
      end
      within ".portlets .gws-notices" do
        expect(page).to have_css(".list-item .datetime", text: I18n.l(item1.released, format: :picker))
      end

      # ポータル - 全庁
      visit gws_portal_group_path(site: site, group: site)
      wait_for_all_turbo_frames
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item .datetime", text: I18n.l(item1.released, format: :picker))
      end
      within ".portlets .gws-notices" do
        expect(page).to have_css(".list-item .datetime", text: I18n.l(item1.released, format: :picker))
      end

      # お知らせ - 閲覧一覧
      visit gws_notice_readables_path(site: site, folder_id: folder, category_id: '-')
      wait_for_all_turbo_frames
      within "[data-id='#{item1.id}']" do
        expect(page).to have_css(".datetime", text: I18n.l(item1.released, format: :picker))
      end

      # お知らせ - 閲覧明細
      visit gws_notice_readable_path(site: site, folder_id: folder, category_id: '-', id: item1)
      wait_for_all_turbo_frames
      within ".aside" do
        expect(page).to have_css(".updated", text: I18n.l(item1.released, format: :picker))
      end

      # お知らせ - バックナンバー一覧
      visit gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
      wait_for_all_turbo_frames
      within "[data-id='#{item2.id}']" do
        expect(page).to have_css(".datetime", text: I18n.l(item2.released, format: :picker))
      end

      # お知らせ - バックナンバー明細
      visit gws_notice_back_number_path(site: site, folder_id: folder, category_id: '-', id: item2)
      wait_for_all_turbo_frames
      within ".aside" do
        expect(page).to have_css(".updated", text: I18n.l(item2.released, format: :picker))
      end
    end
  end

  context "updated date should be shown in management screen" do
    it do
      login_user user, to: gws_notice_editables_path(site: site, folder_id: folder, category_id: '-')
      wait_for_all_turbo_frames
      within "[data-id='#{item1.id}']" do
        expect(page).to have_css(".datetime", text: I18n.l(item1.updated, format: :picker))
      end
      within "[data-id='#{item2.id}']" do
        expect(page).to have_css(".datetime", text: I18n.l(item2.updated, format: :picker))
      end

      visit gws_notice_trashes_path(site: site)
      wait_for_all_turbo_frames
      within "[data-id='#{item3.id}']" do
        expect(page).to have_css(".datetime", text: I18n.l(item3.updated, format: :picker))
      end
    end
  end
end
