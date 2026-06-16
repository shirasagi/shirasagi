require 'spec_helper'

# ドラッグ＆ドロップ経路の試作 feature spec。
#
# 注意:
# jQuery UI の draggable/droppable は mousedown → mousemove(閾値超え) → mouseup の
# イベント列とタイミングに依存し、Selenium での再現は不安定（flaky）になりやすい。
# サーバー側ロジックの確定的な担保は spec/requests/gws/bookmark/items/move_all_spec.rb
# が担い、本 spec は D&D 経路のクライアント側配線（draggable/droppable → buildForm →
# confirm → move_all 送信）が一通りつながっていることを確認する試作という位置づけ。
describe "gws_bookmark_items move_all (drag and drop)", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:root_folder) { user.bookmark_root_folder(site) }
  let!(:folder1) { create :gws_bookmark_folder, cur_user: user, in_parent: root_folder.id }
  let!(:folder2) { create :gws_bookmark_folder, cur_user: user, in_parent: root_folder.id }

  let!(:item1) { create :gws_bookmark_item, cur_user: user, folder: folder1 }
  let!(:item2) { create :gws_bookmark_item, cur_user: user, folder: folder1 }

  let(:index_path) { gws_bookmark_items_path site, folder_id: folder1 }

  before { login_user user }

  # 一覧行 item を、フォルダーツリーの folder ノードへ jQuery UI の D&D で移動する。
  def drag_item_to_folder(item, folder)
    source = find(".index .list-item[data-id='#{item.id}']")
    target = find("#content-navi .tree-navi .tree-item[data-id='#{folder.id}']")

    page.driver.browser.action
      .move_to(source.native)
      .click_and_hold(source.native)
      .move_by(15, 15)        # 最初の mousemove で jQuery UI のドラッグを開始させる
      .move_to(target.native) # ドロップ先ノードへ移動して droppable の hover を発火
      # 2回目の移動で hover/over を確実に再発火させ、Selenium のタイミング依存による
      # droppable 未認識（flaky）を避けるためのワークアラウンド。
      .move_to(target.native)
      .release
      .perform
  end

  context "ブックマーク行をフォルダーツリーへドロップして移動できる" do
    it do
      visit index_path

      within "#content-navi" do
        expect(page).to have_css(".tree-item[data-id='#{folder2.id}'] .item-name", text: folder2.trailing_name)
      end

      expect(item1.folder_id).to eq folder1.id

      page.accept_confirm do
        drag_item_to_folder(item1, folder2)
      end

      wait_for_notice I18n.t('ss.notice.saved')

      # ドラッグした item1 のみが folder2 へ移動し、未選択の item2 は folder1 に残る
      expect(Gws::Bookmark::Item.find(item1.id).folder_id).to eq folder2.id
      expect(Gws::Bookmark::Item.find(item2.id).folder_id).to eq folder1.id
    end
  end
end
