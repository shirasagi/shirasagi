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

describe "cms_agents_parts_print_has_print_display_name", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:print_display_name) { "hogehoge1234" }

  describe "#index" do
    context "when print_display_name is set" do
      let(:print_display_name) { "hogehoge1234" }
      let!(:part) { create :cms_part_print, print_display_name: print_display_name }
      let!(:layout) { create_cms_layout part }
      let!(:top_page) { create :cms_page, layout: layout }

      it "displays print_display_name" do
        visit top_page.full_url
        within "#main" do
          expect(page).to have_css(".btn-ss-print", text: print_display_name)
        end
      end
    end

    context "when print_display_name is not set (nil)" do
      let!(:part) { create :cms_part_print, print_display_name: nil }
      let!(:layout) { create_cms_layout part }
      let!(:top_page) { create :cms_page, layout: layout }

      it "displays part.name" do
        visit top_page.full_url
        within "#main" do
          expect(page).to have_css(".btn-ss-print", text: part.name)
        end
      end
    end
  end
end
