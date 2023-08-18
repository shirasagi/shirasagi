# 本コミットより以前のシラサギでは、リスト機能で配信されたメッセージなどで不正な eml を出力していた。
# この不正な eml をインポートすると、user_settings が空のメッセージが作成される。
# user_settings が空のメッセージは、誰からも・どこからも表示されないデータとなり無駄である。
# 本マイグレーションは、このような無駄なメッセージを削除する。
class SS::Migration20220510000000
  include SS::Migration::Base

  depends_on "20220304000000"

  def change
    cond = {
      "$or" => [
        { user_settings: { "$exists" => false } },
        { user_settings: [] },
        { user_settings: nil }
      ]
    }
    criteria = Gws::Memo::Message.all.where("$and" => [ cond ])
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(1000) do |ids|
      criteria.in(id: ids).destroy_all
    end
  end
end
