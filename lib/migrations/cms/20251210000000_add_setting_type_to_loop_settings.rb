class SS::Migration20251210000000
  include SS::Migration::Base

  depends_on "20251023000000"

  def change
    Cms::LoopSetting.all.find_each(batch_size: 1_000) do |loop_setting|
      # DB に実際に保存されている値を取得（デフォルト値が補完された attributes は使わない）
      raw = loop_setting.collection.find({ "_id" => loop_setting.id }).first || {}
      attrs = {}

      # 既にsetting_typeが設定されている場合はスキップ
      next if raw["setting_type"].present?

      # 「スニペット/」プレフィックスで判定
      name = raw["name"].to_s.presence || loop_setting.name.to_s
      if name.start_with?("スニペット/")
        attrs[:setting_type] = "snippet"
      else
        attrs[:setting_type] = "template"
      end

      loop_setting.set(attrs)
    end
  end
end
