require 'spec_helper'

# D&D・移動ドロップダウンはいずれも同一の move_all エンドポイントへ POST する UI 層に過ぎない。
# jQuery UI の D&D は feature spec で再現しにくいため、ここでサーバー到達と
# 認可・集計再計算のサーバーロジックを直接（かつ決定的・高速に）検証する。
describe "gws_share_files move_all (request)", type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:category) { create :gws_share_category, cur_site: site }

  # ライブラリーA: 最上位 folder0 とその配下 folder1 / folder2
  let!(:folder0) { create :gws_share_folder, cur_site: site }
  let!(:folder1) { create :gws_share_folder, cur_site: site, name: "#{folder0.name}/#{unique_id}" }
  let!(:folder2) { create :gws_share_folder, cur_site: site, name: "#{folder0.name}/#{unique_id}" }
  # ライブラリーB（別の最上位フォルダー＝別部署）
  let!(:other_library) { create :gws_share_folder, cur_site: site }

  let!(:item1) { create :gws_share_file, cur_site: site, folder: folder1, category_ids: [category.id] }
  let!(:item2) { create :gws_share_file, cur_site: site, folder: folder1, category_ids: [category.id] }

  before do
    get sns_auth_token_path(format: :json)
    auth_token = response.parsed_body["auth_token"]
    post sns_login_path(format: :json), params: {
      'authenticity_token' => auth_token,
      'item[email]' => user.email,
      'item[password]' => ss_pass
    }
  end

  def post_move_all(folder, ids: [ item1.id, item2.id ])
    post move_all_gws_share_folder_files_path(site, folder1), params: { ids: ids, folder_id: folder.id }
  end

  context "同一ライブラリー内の別フォルダーへ移動できる" do
    it do
      post_move_all(folder2)
      expect(response.status).to eq 302
      expect(flash[:notice]).to eq I18n.t('ss.notice.saved')

      expect(Gws::Share::File.find(item1.id).folder_id).to eq folder2.id
      expect(Gws::Share::File.find(item2.id).folder_id).to eq folder2.id

      folder1.reload
      expect(folder1.descendants_files_count).to eq 0
      folder2.reload
      expect(folder2.descendants_files_count).to eq 2
    end
  end

  # 入れ子（親子）フォルダー間の移動では、集計の delta+inc 伝播が更新順に依存する。
  # move_all は移動先（dest）を先頭に集計するため、親→子の移動では子（dest）→親（source）
  # の順で再計算され、各フォルダーを最新状態で読み直さないと親の集計が二重計上/欠落する。
  # ここではその経路（reload による補正）を検証する。
  context "入れ子フォルダー（親→子）へ移動しても親の集計が壊れない" do
    let!(:parent_folder) { create :gws_share_folder, cur_site: site }
    let!(:child_folder) { create :gws_share_folder, cur_site: site, name: "#{parent_folder.name}/#{unique_id}" }
    let!(:nested_item1) { create :gws_share_file, cur_site: site, folder: parent_folder, category_ids: [ category.id ] }
    let!(:nested_item2) { create :gws_share_file, cur_site: site, folder: parent_folder, category_ids: [ category.id ] }

    it do
      # 本番ではアップロード等の操作時に集計が更新される。factory 経由では集計が
      # 走らないため、移動前の正しいベースライン（親直下に2件）を作る。
      parent_folder.update_folder_descendants_file_info
      expect(parent_folder.reload.descendants_files_count).to eq 2
      expect(child_folder.reload.descendants_files_count).to eq 0

      # 親 parent_folder にいる状態で、子 child_folder へ一括移動する
      post move_all_gws_share_folder_files_path(site, parent_folder),
        params: { ids: [ nested_item1.id, nested_item2.id ], folder_id: child_folder.id }
      expect(response.status).to eq 302

      expect(Gws::Share::File.find(nested_item1.id).folder_id).to eq child_folder.id
      expect(Gws::Share::File.find(nested_item2.id).folder_id).to eq child_folder.id

      # 子へ移動しても親の総集計（自フォルダー＋子孫）は2件のまま（二重計上/欠落しない）
      total_size = Gws::Share::File.in(id: [ nested_item1.id, nested_item2.id ]).pluck(:size).sum
      parent_folder.reload
      expect(parent_folder.descendants_files_count).to eq 2
      expect(parent_folder.descendants_total_file_size).to eq total_size
      child_folder.reload
      expect(child_folder.descendants_files_count).to eq 2
    end
  end

  context "別ライブラリー（別の最上位フォルダー＝別部署）へも移動できる" do
    it do
      post_move_all(other_library)
      expect(response.status).to eq 302

      expect(Gws::Share::File.find(item1.id).folder_id).to eq other_library.id
      expect(Gws::Share::File.find(item2.id).folder_id).to eq other_library.id

      folder1.reload
      expect(folder1.descendants_files_count).to eq 0
      other_library.reload
      expect(other_library.descendants_files_count).to eq 2
    end
  end

  context "移動先が現在のフォルダーと同一で、実際には何も移動しない場合" do
    it do
      post_move_all(folder1)
      expect(response.status).to eq 302
      expect(flash[:notice]).to eq I18n.t('gws/share.notice.move_none')

      expect(Gws::Share::File.find(item1.id).folder_id).to eq folder1.id
      expect(Gws::Share::File.find(item2.id).folder_id).to eq folder1.id

      folder1.reload
      expect(folder1.descendants_files_count).to eq 2
    end
  end

  context "存在しない移動先フォルダーを指定した場合" do
    it do
      post move_all_gws_share_folder_files_path(site, folder1), params: { ids: [ item1.id, item2.id ], folder_id: 9_999_999 }
      expect(response.status).to eq 404

      # 何も移動していないこと
      expect(Gws::Share::File.find(item1.id).folder_id).to eq folder1.id
      expect(Gws::Share::File.find(item2.id).folder_id).to eq folder1.id
    end
  end
end
