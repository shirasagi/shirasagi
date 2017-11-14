require 'spec_helper'

describe "gws_circular_trashes", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_circular_post, :gws_circular_trashes }
  let(:item2) { create :gws_circular_post, :gws_circular_trashes_item2 }
  let(:item3) { create :gws_circular_post, :gws_circular_trashes_item3 }
  let(:item4) { create :gws_circular_post, :gws_circular_trashes_item4 }
  let(:item5) { create :gws_circular_post, :gws_circular_trashes_item5 }
  let(:item6) { create :gws_circular_post, :gws_circular_trashes_item6 }
  let(:index_path) { gws_circular_trashes_path site, gws_user }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index only user_ids" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#index only group_ids" do
      item2
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item2.name)
    end

    it "#index not display except deleted" do
      item3
      visit index_path
      wait_for_ajax
      expect(page).not_to have_content(item3.name)
    end

    it "#index not display only member_ids" do
      item4
      visit index_path
      wait_for_ajax
      expect(page).not_to have_content(item4.name)
    end

    it "#index not display only readable_member_ids" do
      item5
      visit index_path
      wait_for_ajax
      expect(page).not_to have_content(item5.name)
    end

    it "#index not display only readable_group_ids" do
      item6
      visit index_path
      wait_for_ajax
      expect(page).not_to have_content(item6.name)
    end

    it "#show only user_ids" do
      item
      visit "/.g#{site._id}/circular/trashes/#{item.id}"
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#show only group_ids" do
      item2
      visit "/.g#{site._id}/circular/trashes/#{item2.id}"
      wait_for_ajax
      expect(page).to have_content(item2.name)
    end
  end
end