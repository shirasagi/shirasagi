require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now.beginning_of_minute }

  let!(:post1) do
    create(:gws_circular_post, due_date: now + 1.day, member_ids: [user.id], state: "public")
  end
  let!(:post2) do
    create(:gws_circular_post, due_date: now + 2.days, member_ids: [user.id], state: "public")
  end
  let!(:post3) do
    create(:gws_circular_post, due_date: now + 3.days, member_ids: [user.id], state: "public")
  end
  let!(:post4) do
    create(:gws_circular_post, due_date: now + 4.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post5) do
    create(:gws_circular_post, due_date: now + 5.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post6) do
    create(:gws_circular_post, due_date: now + 6.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let(:index_path) { gws_circular_main_path(site: site) }

  context "show default (site's both)" do
    before { login_gws_user }

    it do
      visit index_path
      within ".list-items" do
        expect(page).to have_link post1.name
        expect(page).to have_link post2.name
        expect(page).to have_link post3.name
        expect(page).to have_link post4.name
        expect(page).to have_link post5.name
        expect(page).to have_link post6.name
      end
    end
  end

  context "show unseen" do
    before do
      login_gws_user
      site.circular_article_state = "unseen"
      site.update!
    end

    it do
      visit index_path
      within ".list-items" do
        expect(page).to have_link post1.name
        expect(page).to have_link post2.name
        expect(page).to have_link post3.name
        expect(page).to have_no_link post4.name
        expect(page).to have_no_link post5.name
        expect(page).to have_no_link post6.name
      end

      within ".search" do
        select I18n.t("gws/circular.options.article_state.both"), from: "s[article_state]"
        click_on I18n.t("ss.buttons.search")
      end

      within ".list-items" do
        expect(page).to have_link post1.name
        expect(page).to have_link post2.name
        expect(page).to have_link post3.name
        expect(page).to have_link post4.name
        expect(page).to have_link post5.name
        expect(page).to have_link post6.name
      end
    end
  end
end
