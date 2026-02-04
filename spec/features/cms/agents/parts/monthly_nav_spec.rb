require 'spec_helper'

describe "cms_agents_parts_monthly_nav", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node_archive, cur_site: site, layout_id: layout.id, filename: "node" }
  let(:index_url) { "#{node.full_url}#{Time.zone.now.year}#{format('%02d', Time.zone.now.month)}" }
  let(:part) { create :cms_part_monthly_nav, filename: "node/part", periods: 24 }

  context "public" do
    let!(:item) { create :article_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"

      # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
      FileUtils.rm_rf site.path
      FileUtils.mkdir_p site.path
    end

    it "#index" do
      visit index_url
      expect(status_code).to eq 200
      expect(page).to have_css(".monthly-nav")
    end
  end
end
