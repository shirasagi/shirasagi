require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  describe "set seen" do
    let!(:item) { create :gws_circular_post, :gws_circular_posts }

    it do
      item.reload
      save_updated = item.updated
      save_created = item.created

      expect(item.seen?(gws_user)).to be_falsey

      visit gws_circular_main_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item.unread .seen", text: I18n.t("gws/circular.post.unseen"))
      end

      click_on item.name
      within "#post-#{item.id}" do
        click_on I18n.t("gws/circular.post.set_seen")
      end
      wait_for_notice I18n.t("ss.notice.set_seen")

      item.reload
      expect(item.seen?(gws_user)).to be_truthy
      expect(item.updated).to eq save_updated
      expect(item.created).to eq save_created

      visit gws_circular_main_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .seen", text: I18n.t("gws/circular.post.seen"))
      end
    end
  end

  describe "set seen with see_type 'simple'" do
    let!(:item) { create :gws_circular_post, :gws_circular_posts, see_type: "simple" }

    it do
      item.reload
      save_updated = item.updated
      save_created = item.created

      expect(item.seen?(gws_user)).to be_falsey

      visit gws_circular_main_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item.unread .seen", text: I18n.t("gws/circular.post.unseen"))
      end

      click_on item.name

      item.reload
      expect(item.seen?(gws_user)).to be_truthy
      expect(item.updated).to eq save_updated
      expect(item.created).to eq save_created

      visit gws_circular_main_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .seen", text: I18n.t("gws/circular.post.seen"))
      end
    end
  end

  describe "unset seen" do
    let!(:item2) { create :gws_circular_post, :gws_circular_posts_item2 }

    it do
      item2.reload
      save_updated = item2.updated
      save_created = item2.created

      expect(item2.seen?(gws_user)).to be_truthy

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .seen", text: I18n.t("gws/circular.post.seen"))
      end

      click_on item2.name
      within "#post-#{item2.id}" do
        click_on I18n.t("gws/circular.post.unset_seen")
      end
      wait_for_notice I18n.t("ss.notice.unset_seen")

      item2.reload
      expect(item2.unseen?(gws_user)).to be_truthy
      expect(item2.updated).to eq save_updated
      expect(item2.created).to eq save_created

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item.unread .seen", text: I18n.t("gws/circular.post.unseen"))
      end
    end
  end

  describe "unset seen with see_type 'simple'" do
    let!(:item2) { create :gws_circular_post, :gws_circular_posts_item2, see_type: "simple" }

    it do
      item2.reload
      save_updated = item2.updated
      save_created = item2.created

      expect(item2.seen?(gws_user)).to be_truthy

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .seen", text: I18n.t("gws/circular.post.seen"))
      end

      click_on item2.name
      within "#post-#{item2.id}" do
        expect(page).to have_no_link(I18n.t("gws/circular.post.set_seen"))
        expect(page).to have_no_link(I18n.t("gws/circular.post.unset_seen"))
      end

      expect(item2.seen?(gws_user)).to be_truthy
      expect(item2.updated).to eq save_updated
      expect(item2.created).to eq save_created
    end
  end

  describe "set seen all" do
    let!(:item) { create :gws_circular_post, :gws_circular_posts }

    it do
      item.reload
      save_updated = item.updated
      save_created = item.created

      expect(item.seen?(gws_user)).to be_falsey

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item.unread .seen", text: I18n.t("gws/circular.post.unseen"))
      end

      first(".list-item input[value='#{item.id}']").click
      within ".list-head-action" do
        page.accept_alert do
          click_on I18n.t("gws/circular.post.set_seen")
        end
      end
      wait_for_notice I18n.t("ss.notice.set_seen")

      item.reload
      expect(item.seen?(gws_user)).to be_truthy
      expect(item.updated).to eq save_updated
      expect(item.created).to eq save_created

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .seen", text: I18n.t("gws/circular.post.seen"))
      end
    end
  end

  describe "set seen all with see_type 'simple'" do
    let!(:item) { create :gws_circular_post, :gws_circular_posts, see_type: "simple" }

    it do
      item.reload
      save_updated = item.updated
      save_created = item.created

      expect(item.seen?(gws_user)).to be_falsey

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item.unread .seen", text: I18n.t("gws/circular.post.unseen"))
      end

      first(".list-item input[value='#{item.id}']").click
      within ".list-head-action" do
        page.accept_alert do
          click_on I18n.t("gws/circular.post.set_seen")
        end
      end
      wait_for_notice I18n.t("ss.notice.set_seen")

      item.reload
      expect(item.seen?(gws_user)).to be_truthy
      expect(item.updated).to eq save_updated
      expect(item.created).to eq save_created

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .seen", text: I18n.t("gws/circular.post.seen"))
      end
    end
  end

  describe "unset seen all" do
    let!(:item2) { create :gws_circular_post, :gws_circular_posts_item2 }

    it do
      item2.reload
      save_updated = item2.updated
      save_created = item2.created

      expect(item2.seen?(gws_user)).to be_truthy

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .seen", text: I18n.t("gws/circular.post.seen"))
      end

      first(".list-item input[value='#{item2.id}']").click
      within ".list-head-action" do
        page.accept_alert do
          click_on I18n.t("gws/circular.post.unset_seen")
        end
      end
      wait_for_notice I18n.t("ss.notice.unset_seen")

      item2.reload
      expect(item2.unseen?(gws_user)).to be_truthy
      expect(item2.updated).to eq save_updated
      expect(item2.created).to eq save_created

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item.unread .seen", text: I18n.t("gws/circular.post.unseen"))
      end
    end
  end

  describe "unset seen all with see_type 'simple'" do
    let!(:item2) { create :gws_circular_post, :gws_circular_posts_item2, see_type: "simple" }

    it do
      item2.reload
      save_updated = item2.updated
      save_created = item2.created

      expect(item2.seen?(gws_user)).to be_truthy

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .seen", text: I18n.t("gws/circular.post.seen"))
      end

      first(".list-item input[value='#{item2.id}']").click
      within ".list-head-action" do
        page.accept_alert do
          click_on I18n.t("gws/circular.post.unset_seen")
        end
      end
      wait_for_notice I18n.t("ss.notice.unset_seen")

      item2.reload
      expect(item2.unseen?(gws_user)).to be_truthy
      expect(item2.updated).to eq save_updated
      expect(item2.created).to eq save_created

      visit gws_circular_posts_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item.unread .seen", text: I18n.t("gws/circular.post.unseen"))
      end
    end
  end
end
