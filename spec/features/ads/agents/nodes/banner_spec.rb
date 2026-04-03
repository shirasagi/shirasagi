require 'spec_helper'

describe "ads_agents_nodes_banner", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :ads_node_banner, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :ads_banner, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"

      # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
      FileUtils.rm_rf site.path
      FileUtils.mkdir_p site.path
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
    end
  end
end
