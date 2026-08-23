module SS::Copy::CmsLoopSettings
  extend ActiveSupport::Concern

  # ループHTML(共有)はサイト単位の共有リソースで、フォルダー複製は同一サイト内で行われる。
  # そのため複製せず、複製先にも同じ設定を参照させる（レイアウト・定型フォームと同じ扱い）。
  def resolve_loop_setting_reference(id)
    id
  end
end
