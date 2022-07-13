# v1.16.0 で ZIP を 64-bit かつ Unicode モードで出力するようにしましたが、
# ファイル名のエンコードに問題があり、文字化けする ZIP ファイルを作成するようになっていました。
# グループウェアの照会回答は、添付ファイルを ZIP ファイルで一括ダウンロードする機能がありますが、
# 作成した ZIP を private/ 以下に保存しておき、2 回目の要求以降は作成済みのファイルを応答します。
# このファイルが文字化けする状態で作成されている可能性があるため、全て削除するようにします。
class SS::Migration20220705000000
  include SS::Migration::Base

  depends_on "20220526000000"

  def change
    root_path = Gws::Monitor::Topic.download_root_path
    ::FileUtils.rm_rf(root_path)
  end
end
