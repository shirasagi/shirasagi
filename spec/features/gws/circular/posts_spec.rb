require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_circular_post, :gws_circular_posts }
  let(:item2) { create :gws_circular_post, :gws_circular_posts_item2 }
  let(:item3) { create :gws_circular_post, :gws_circular_posts_item3 }
  let(:item4) { create :gws_circular_post, :gws_circular_posts_item4 }
  let(:index_path) { gws_circular_posts_path site, gws_user }
  let(:new_path) { new_gws_circular_post_path site, gws_user }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#index display unseen" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content('未読')
    end

    it "#index display seen" do
      item2
      visit index_path
      wait_for_ajax
      expect(page).to have_content('既読')
    end

    it "#new" do
      visit new_path
      wait_for_ajax
      expect(page).to have_content('基本情報')
    end

    it "#edit" do
      item
      visit "/.g#{site._id}/circular/posts/#{item.id}/edit"
      wait_for_ajax
      expect(page).to have_content('基本情報')
    end

    it "#show" do
      item
      visit "/.g#{site._id}/circular/posts/#{item.id}"
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#show only member_ids" do
      item
      visit "/.g#{site._id}/circular/posts/#{item.id}"
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#show only readable_member_ids" do
      item3
      visit "/.g#{site._id}/circular/posts/#{item.id}"
      wait_for_ajax
      expect(page).to have_content(item3.name)
    end

    it "#show only readable_group_ids" do
      item4
      visit "/.g#{site._id}/circular/posts/#{item.id}"
      wait_for_ajax
      expect(page).to have_content(item4.name)
    end
  end
end
