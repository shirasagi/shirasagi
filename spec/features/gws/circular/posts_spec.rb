require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example do
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
      item
      visit index_path
      expect(page).to have_content('未読')
    end

    it "#index display seen" do
      item2
      visit index_path
      expect(page).to have_content('既読')
    end

    it "#show" do
      item
      visit gws_circular_post_path(site, item)
      expect(page).to have_content(item.name)
    end
  end
end
