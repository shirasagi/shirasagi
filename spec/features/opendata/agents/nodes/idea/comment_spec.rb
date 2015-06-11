require 'spec_helper'

describe "opendata_agents_nodes_comment", dbscope: :example do
  let(:site) { cms_site }
  let!(:node_idea) { create_once :opendata_node_idea, name: "opendata_idea" }
  let!(:node_search) { create_once :opendata_node_search_idea }
  let!(:node_mypage) { create_once :opendata_node_mypage, filename: "mypage" }
  let!(:node_login) { create :member_node_login, redirect_url: node_idea.url }

  let!(:category) { create_once :opendata_node_category }
  let!(:area) { create_once :opendata_node_area }
  let!(:idea) do
    create_once :opendata_idea,
    filename: "#{node_idea.filename}/1.html",
    category_ids: [ category.id ],
    area_ids: [ area.id ]
  end
  let(:index_path) { "#{node_idea.url}#{idea.id}/comment/show.html" }

  context "without auth" do
    it "#index" do
      visit "http://#{site.domain}#{index_path}"
      expect(current_path).to eq index_path
      expect(page).to have_selector "div.invite"
    end
  end

  context "with auth" do
    before do
      login_opendata_member(site, node_login)
    end

    after do
      logout_opendata_member(site, node_login)
    end

    it "#index" do
      visit "http://#{site.domain}#{index_path}"
      expect(current_path).to eq index_path
      expect(page).to have_selector "a.comment-add"
    end

#    it "#add" do
#      visit "http://#{site.domain}#{index_path}"
#      fill_in "s_comment_body", with: "管理コメント０１"
#      click_link "コメントを投稿"
#    end
  end
end
