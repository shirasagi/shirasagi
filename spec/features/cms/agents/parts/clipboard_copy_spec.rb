require 'spec_helper'

describe "cms_agents_parts_clipboard_copy", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  context "when clipboard_copy_target is url" do
    let!(:layout) { create_cms_layout part }
    let!(:top_page) { create :cms_page, layout: layout }
    let!(:part) { create :cms_part_clipboard_copy, clipboard_copy_target: 'url' }

    it do
      # 自動制御された Chrome では clipboard 機能が無効化されるので、あまり有効なテストはできない。
      visit top_page.full_url + "?a=b"
      within "#main" do
        expect(page).to have_css(".btn-ss-clipboard-copy", text: part.name)
      end
    end
  end
end

describe "cms_agents_parts_clipboard_copy_has_clipboard_display_name", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  context "when clipboard_copy_target is url" do
    let!(:layout) { create_cms_layout part }
    let!(:top_page) { create :cms_page, layout: layout }

    context "when clipboard_display_name is set" do
      let(:clipboard_display_name) { "hogehoge1234" }
      let!(:part) do
        create :cms_part_clipboard_copy, clipboard_copy_target: 'url', clipboard_display_name: clipboard_display_name
      end

      it "displays the clipboard copy button with the correct display name" do
        visit top_page.full_url + "?a=b"
        within "#main" do
          expect(page).to have_css(".btn-ss-clipboard-copy", text: clipboard_display_name)
        end
      end
    end

    context "when clipboard_display_name is nil" do
      let!(:part) { create :cms_part_clipboard_copy, clipboard_copy_target: 'url', clipboard_display_name: nil }

      it "displays the clipboard copy button with the default name" do
        visit top_page.full_url + "?a=b"
        within "#main" do
          expect(page).to have_css(".btn-ss-clipboard-copy", text: part.name)
        end
      end
    end
  end
end
