require 'spec_helper'

describe "cms_agents_parts_print", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  describe "#index" do
    let!(:layout) { create_cms_layout part }
    let!(:top_page) { create :cms_page, layout: layout }
    let!(:part) { create :cms_part_print }

    it do
      # 印刷ボタンをクリックすると、印刷用モーダルダイアログが開く。
      # その後、印刷用モーダルダイアログが閉じられるまで制御が帰ってこないので、あまり有効なテストはできない。
      visit top_page.full_url
      within "#main" do
        expect(page).to have_css(".btn-ss-print", text: part.name)
      end
    end
  end
end
