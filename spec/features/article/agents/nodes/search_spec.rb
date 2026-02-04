require 'spec_helper'

describe "article_agents_nodes_search", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :article_node_search, layout_id: layout.id, filename: "node" }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"

      # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
      FileUtils.rm_rf site.path
      FileUtils.mkdir_p site.path
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".article-search")
    end
  end
end
