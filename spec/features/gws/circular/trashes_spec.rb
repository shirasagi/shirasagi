require 'spec_helper'

describe "gws_circular_trashes", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_circular_post, :gws_circular_trashes }
  let(:item2) { create :gws_circular_post, :gws_circular_trashes_item2 }
  let(:item3) { create :gws_circular_post, :gws_circular_trashes_item3 }
  let(:item4) { create :gws_circular_post, :gws_circular_trashes_item4 }

  context "with auth" do
    before { login_gws_user }

    it "#index only user_ids" do
      item
      visit gws_circular_trashes_path(site)
      expect(page).to have_content(item.name)
    end

    it "#index only group_ids" do
      item2
      visit gws_circular_trashes_path(site)
      expect(page).to have_content(item2.name)
    end

    it "#index not display except deleted" do
      item3
      visit gws_circular_trashes_path(site)
      expect(page).to have_no_content(item3.name)
    end

    it "#index not display only member_ids" do
      item4
      visit gws_circular_trashes_path(site)
      expect(page).to have_no_content(item4.name)
    end

    it "#show only user_ids" do
      item
      visit gws_circular_trash_path(site, item)
      expect(page).to have_content(item.name)
    end

    it "#show only group_ids" do
      item2
      visit gws_circular_trash_path(site, item2)
      expect(page).to have_content(item2.name)
    end
  end
end
