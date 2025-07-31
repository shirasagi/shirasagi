require 'spec_helper'

describe "cms_preview_without_filename", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }
  let(:user) { cms_user }
  let(:new_path) { new_article_page_path site.id, node.id }

  before do
    login_cms_user
    setup_preview_with_title_layout
  end

  context "with article page preview" do
    it "preview works without filename" do
      visit new_path

      # タイトルを入力（ファイル名は入力しない）
      within "form#item-form" do
        fill_in "item[name]", with: "test article"
        fill_in_ckeditor "item[html]", with: html
        select @preview_layout.name, from: 'item[layout_id]'
      end
      page.first("footer.send .preview").click
      switch_to_window(windows.last)
      wait_for_document_loading

      # プレビューウィンドウが開くことを確認
      expect(windows.size).to eq(2)

      # プレビューが正常に表示されることを確認
      expect(page).to have_content("test article")
      expect(page).to have_css("h2", text: "見出し2")
      expect(page).to have_css("p", text: "内容が入ります。")
      expect(page).to have_css("h3", text: "見出し3")
      expect(page).to have_css("p", text: "内容が入ります。内容が入ります。")
      expect(page).not_to have_content(I18n.t("errors.messages.set_filename"))
    end

    it "preview works without title and filename" do
      visit new_path

      # タイトルもファイル名も入力しない
      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html
        select @preview_layout.name, from: 'item[layout_id]'
      end
      page.first("footer.send .preview").click
      switch_to_window(windows.last)
      wait_for_document_loading

      # プレビューウィンドウが開くことを確認
      expect(windows.size).to eq(2)

      # プレビューが正常に表示されることを確認（デフォルトタイトルが表示される）
      expect(page).to have_content(I18n.t("cms.preview_title"))
      expect(page).to have_css("h2", text: "見出し2")
      expect(page).to have_css("p", text: "内容が入ります。")
      expect(page).to have_css("h3", text: "見出し3")
      expect(page).to have_css("p", text: "内容が入ります。内容が入ります。")
      expect(page).not_to have_content(I18n.t("errors.messages.set_filename"))
    end
  end
end
