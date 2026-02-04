require 'spec_helper'

describe "member_agents_nodes_blog", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :member_node_blog, layout_id: layout.id, filename: "node" }
  let(:blog_layout) { create :member_blog_layout }

  context "public" do
    let!(:item) { create :member_node_blog_page, layout_id: blog_layout.id, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"

      # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
      FileUtils.rm_rf site.path
      FileUtils.mkdir_p site.path
    end

    it "#index" do
      visit node.url
      expect(page).to have_selector("div.member-blogs")
      expect(page).to have_selector("article.blog.thumb")
      expect(page).to have_selector("img.thumb")

      first('.member-blogs a').click
      expect(current_path).to eq item.url
    end
  end
end
