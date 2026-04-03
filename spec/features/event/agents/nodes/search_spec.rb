require 'spec_helper'

describe "event_agents_nodes_search", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :event_node_search, layout_id: layout.id, filename: "node" }
  let!(:event_recur1) do
    { kind: "date", start_at: Time.zone.today - 3.days, frequency: "daily", until_on: Time.zone.today - 2.days }
  end
  let!(:event_recur2) do
    { kind: "date", start_at: Time.zone.today - 1.day, frequency: "daily", until_on: Time.zone.today + 1.day }
  end
  let!(:event_recur3) do
    { kind: "date", start_at: Time.zone.today + 2.days, frequency: "daily", until_on: Time.zone.today + 3.days }
  end
  let!(:item1) { create :event_page, cur_node: node, event_recurrences: [event_recur1] }
  let!(:item2) { create :event_page, cur_node: node, event_recurrences: [event_recur2] }
  let!(:item3) { create :event_page, cur_node: node, event_recurrences: [event_recur3] }

  before do
    # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
    FileUtils.rm_rf site.path
    FileUtils.mkdir_p site.path
  end

  context 'when sort is updated_desc' do
    it "index" do
      visit node.full_url
      select I18n.t('cms.sort_options.updated_desc.title'), from: "sort"
      click_button I18n.t('event.submit.search')

      expect(page).to have_selector('article', count: 3)
      expect(page).to have_css("article:nth-child(1) a", text: item3.name)
      expect(page).to have_css("article:nth-child(2) a", text: item2.name)
      expect(page).to have_css("article:nth-child(3) a", text: item1.name)
    end
  end

  context 'when sort is unfinished_event_dates' do
    it "index" do
      visit node.full_url
      select I18n.t('event.sort_options.unfinished_event_dates.title'), from: "sort"
      click_button I18n.t('event.submit.search')

      expect(page).to have_selector('article', count: 2)
      expect(page).to have_css("article:nth-child(1) a", text: item2.name)
      expect(page).to have_css("article:nth-child(2) a", text: item3.name)
    end
  end
end
