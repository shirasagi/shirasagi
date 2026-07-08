require 'spec_helper'

# ドラッグ＆ドロップ経路の試作 feature spec。
#
# 注意:
# jQuery UI の draggable/droppable は mousedown → mousemove(閾値超え) → mouseup の
# イベント列とタイミングに依存し、Selenium での再現は不安定（flaky）になりやすい。
# shirasagi 全体でも D&D 操作そのものを駆動する feature spec の前例は無く、踏襲元の
# gws/memo/messages/move_all_spec.rb もドロップダウン経路のみを検証している。
# そのためサーバー側ロジック（認可・集計再計算など）の確定的な担保は
# spec/requests/gws/share/files/move_all_spec.rb が担い、本 spec は D&D 経路の
# クライアント側配線（draggable/droppable → buildForm → confirm → move_all 送信）が
# 一通りつながっていることを確認する試作という位置づけ。
describe "gws_share_files move_all (drag and drop)", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:category) { create :gws_share_category, cur_site: site }

  # ライブラリーA: 最上位 folder0 とその配下 folder1
  let!(:folder0) { create :gws_share_folder, cur_site: site }
  let!(:folder1) { create :gws_share_folder, cur_site: site, name: "#{folder0.name}/#{unique_id}" }

  let!(:item1) { create :gws_share_file, cur_site: site, folder: folder1, category_ids: [ category.id ] }
  let!(:item2) { create :gws_share_file, cur_site: site, folder: folder1, category_ids: [ category.id ] }

  let(:index_path) { gws_share_folder_files_path site, folder1 }

  # 一覧行 item を、フォルダーツリーの folder ノードへ jQuery UI の D&D で移動する。
  # ドラッグ開始は行中央（ファイル名リンク付近）から行う。jQuery UI draggable は
  # 既定で input 系を cancel するため、チェックボックスからは開始しないこと。
  def drag_file_to_folder(item, folder)
    source = find(".gws-schedule-file-main .list-item[data-id='#{item.id}']")
    target = find("#gws-share-file-folder-list .tree-navi .tree-item[data-id='#{folder.id}']")

    page.driver.browser.action
      .move_to(source.native)
      .click_and_hold(source.native)
      .move_by(15, 15)        # 最初の mousemove で jQuery UI のドラッグを開始させる
      .move_to(target.native) # ドロップ先ノードへ移動して droppable の hover を発火
      .move_to(target.native)
      .release
      .perform
  end

  context "ファイル行をフォルダーツリーへドロップして移動できる" do
    it do
      login_gws_user to: index_path

      # ツリーが描画され、移動先（親フォルダー folder0）が drop 先ノードとして現れるまで待つ
      within ".tree-navi" do
        expect(page).to have_css(".tree-item[data-id='#{folder0.id}'] .item-name", text: folder0.name)
      end

      expect(item1.folder_id).to eq folder1.id

      # ドロップ時に確認ダイアログが出るので受け入れる
      page.accept_confirm do
        drag_file_to_folder(item1, folder0)
      end

      wait_for_notice I18n.t('ss.notice.saved')

      # ドラッグした item1 のみが folder0 へ移動し、未選択の item2 は folder1 に残る
      expect(Gws::Share::File.find(item1.id).folder_id).to eq folder0.id
      expect(Gws::Share::File.find(item2.id).folder_id).to eq folder1.id

      # 子→親の入れ子移動でも集計がズレない:
      # folder0 = item1(直下) + folder1 配下の item2 = 2 件
      folder0.reload
      expect(folder0.descendants_files_count).to eq 2
      folder1.reload
      expect(folder1.descendants_files_count).to eq 1
    end
  end
end
