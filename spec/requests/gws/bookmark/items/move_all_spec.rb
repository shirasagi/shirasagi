require 'spec_helper'

# ブックマークの一括移動（移動ドロップダウン／ドラッグ&ドロップが叩く move_all
# エンドポイント）のサーバーロジックを、ブラウザ非依存で決定的に検証する。
describe "gws_bookmark_items move_all (request)", type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:root_folder) { user.bookmark_root_folder(site) }
  let!(:folder1) { create :gws_bookmark_folder, cur_user: user, in_parent: root_folder.id }
  let!(:folder2) { create :gws_bookmark_folder, cur_user: user, in_parent: root_folder.id }

  let!(:item1) { create :gws_bookmark_item, cur_user: user, folder: folder1 }
  let!(:item2) { create :gws_bookmark_item, cur_user: user, folder: folder1 }

  before do
    get sns_auth_token_path(format: :json)
    auth_token = response.parsed_body["auth_token"]
    post sns_login_path(format: :json), params: {
      'authenticity_token' => auth_token,
      'item[email]' => user.email,
      'item[password]' => ss_pass
    }
  end

  # flash の notice はコントローラがリクエスト時のロケールで翻訳して格納するため、
  # spec 側の I18n.locale（locale.rb がランダムに選ぶ）と一致するとは限らない。
  # ロケールに依存せず「どの notice キーが使われたか」を検証するため、
  # 利用可能な全ロケールの翻訳のいずれかと一致することを確認する。
  def notice_translations(key)
    I18n.available_locales.map { |locale| I18n.t(key, locale: locale) }
  end

  def post_move_all(dst, ids: [ item1.id, item2.id ], from: folder1)
    post move_all_gws_bookmark_items_path(site, folder_id: from), params: { ids: ids, dst_folder_id: dst.id }
  end

  context "別フォルダーへ一括移動できる" do
    it do
      post_move_all(folder2)
      expect(response.status).to eq 302
      expect(notice_translations('ss.notice.saved')).to include(flash[:notice])

      expect(Gws::Bookmark::Item.find(item1.id).folder_id).to eq folder2.id
      expect(Gws::Bookmark::Item.find(item2.id).folder_id).to eq folder2.id
    end
  end

  context "ルートフォルダーへも一括移動できる" do
    it do
      post_move_all(root_folder)
      expect(response.status).to eq 302

      expect(Gws::Bookmark::Item.find(item1.id).folder_id).to eq root_folder.id
      expect(Gws::Bookmark::Item.find(item2.id).folder_id).to eq root_folder.id
    end
  end

  context "移動先が現在のフォルダーと同一で、実際には何も移動しない場合" do
    it do
      post_move_all(folder1)
      expect(response.status).to eq 302
      expect(notice_translations('gws/bookmark.notice.move_none')).to include(flash[:notice])

      expect(Gws::Bookmark::Item.find(item1.id).folder_id).to eq folder1.id
      expect(Gws::Bookmark::Item.find(item2.id).folder_id).to eq folder1.id
    end
  end

  context "存在しない移動先フォルダーを指定した場合" do
    it do
      post move_all_gws_bookmark_items_path(site, folder_id: folder1),
        params: { ids: [ item1.id, item2.id ], dst_folder_id: 9_999_999 }
      expect(response.status).to eq 404

      expect(Gws::Bookmark::Item.find(item1.id).folder_id).to eq folder1.id
      expect(Gws::Bookmark::Item.find(item2.id).folder_id).to eq folder1.id
    end
  end

  context "他ユーザーのフォルダーは移動先にできない" do
    let!(:other_user) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
    let!(:other_folder) { other_user.bookmark_root_folder(site) }

    it do
      post move_all_gws_bookmark_items_path(site, folder_id: folder1),
        params: { ids: [ item1.id, item2.id ], dst_folder_id: other_folder.id }
      expect(response.status).to eq 404

      expect(Gws::Bookmark::Item.find(item1.id).folder_id).to eq folder1.id
      expect(Gws::Bookmark::Item.find(item2.id).folder_id).to eq folder1.id
    end
  end

  context "細工された ids[] に他ユーザーのブックマークを混ぜても名前を漏らさない" do
    let!(:other_user) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
    let!(:other_folder) { other_user.bookmark_root_folder(site) }
    let!(:other_item) do
      create :gws_bookmark_item, cur_user: other_user, folder: other_folder, name: "他人の秘密ブックマーク"
    end

    it do
      post move_all_gws_bookmark_items_path(site, folder_id: folder1),
        params: { ids: [ item1.id, other_item.id ], dst_folder_id: folder2.id }
      expect(response.status).to eq 302

      # 権限エラーで弾いた項目があるため、名前を含まない汎用メッセージにフォールバックする
      expect(notice_translations('errors.messages.auth_error')).to include(flash[:notice])
      expect(flash[:notice]).not_to include(other_item.name)

      # 自分の item1 は移動でき、他ユーザーの項目は元のフォルダーから動かない
      expect(Gws::Bookmark::Item.find(item1.id).folder_id).to eq folder2.id
      expect(Gws::Bookmark::Item.find(other_item.id).folder_id).to eq other_folder.id
    end
  end
end
