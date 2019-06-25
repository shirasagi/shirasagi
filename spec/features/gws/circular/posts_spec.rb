require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:item) { create :gws_circular_post, :gws_circular_posts }
  let(:item2) { create :gws_circular_post, :gws_circular_posts_item2 }
  let(:index_path) { gws_circular_posts_path(site) }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      expect(page).to have_content(item.name)
    end

    it "#index display unseen" do
      expect(item.seen?(gws_user)).to be_falsey

      visit index_path
      expect(page).to have_content(I18n.t("gws/circular.post.unseen"))

      first(".list-item input[value='#{item.id}']").click
      within ".list-head-action" do
        page.accept_alert do
          click_on I18n.t("gws/circular.post.set_seen")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.set_seen"))

      item.reload
      expect(item.seen?(gws_user)).to be_truthy

      visit index_path
      expect(page).to have_content(I18n.t("gws/circular.post.seen"))
    end

    it "#index display seen" do
      expect(item2.seen?(gws_user)).to be_truthy

      visit index_path
      expect(page).to have_content(I18n.t("gws/circular.post.seen"))

      first(".list-item input[value='#{item2.id}']").click
      within ".list-head-action" do
        page.accept_alert do
          click_on I18n.t("gws/circular.post.unset_seen")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.unset_seen"))

      item2.reload
      expect(item2.unseen?(gws_user)).to be_truthy

      visit index_path
      expect(page).to have_content(I18n.t("gws/circular.post.unseen"))
    end

    it "#show" do
      item
      visit gws_circular_post_path(site, item)
      expect(page).to have_content(item.name)
    end
  end
end
