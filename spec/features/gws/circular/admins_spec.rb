require 'spec_helper'

describe "gws_circular_admins", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create(:gws_circular_post, :gws_circular_posts) }
  let(:item2) { create(:gws_circular_post, :gws_circular_posts_item2) }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item
      visit gws_circular_admins_path(site)
      expect(page).to have_content(item.name)
    end

    it "#new" do
      visit new_gws_circular_admin_path(site)
      expect(page).to have_content('基本情報')
    end

    it "#edit" do
      item
      visit edit_gws_circular_admin_path(site, item)
      expect(page).to have_content('基本情報')
    end

    it "#show" do
      item
      visit gws_circular_admin_path(site, item)
      expect(page).to have_content(item.name)
    end

    it "#show only member_ids" do
      item
      visit gws_circular_admin_path(site, item)
      expect(page).to have_content(item.name)
    end
  end
end
