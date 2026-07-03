require 'spec_helper'

describe "event_agents_nodes_page", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :event_node_page, cur_site: site, layout: layout }
  let!(:item1) { create :event_page, cur_site: site, cur_node: node, layout: layout, ical_link: nil }

  before do
    # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
    FileUtils.rm_rf site.path
    FileUtils.mkdir_p site.path
  end

  it do
    visit item1.full_url
    expect(page).to have_css("[rel=\"canonical\"][href=\"#{item1.full_url}\"]")
  end
end
