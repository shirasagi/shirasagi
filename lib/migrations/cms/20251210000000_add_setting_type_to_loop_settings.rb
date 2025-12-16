class SS::Migration20251210000000
  include SS::Migration::Base

  depends_on "20251023000000"

  def change
    Cms::LoopSetting.all.find_in_batches(batch_size: 1_000) do |loop_settings|
      batch_ids = loop_settings.map(&:id).compact

      # DB に実際に保存されている値を取得（デフォルト値が補完された attributes は使わない）
      raw_by_id = Cms::LoopSetting.collection.find({ "_id" => { "$in" => batch_ids } }).to_a.index_by { |doc| doc["_id"] }

      loop_settings.each do |loop_setting|
        raw = raw_by_id[loop_setting.id] || {}
        attrs = {}

        if raw.blank?
          Rails.logger.info("SS::Migration20251210000000 skip Cms::LoopSetting##{loop_setting.id}: raw doc is missing")
          next
        end

        # 既にsetting_typeが設定されている場合はスキップ
        next if raw["setting_type"].present?

        # 「スニペット/」プレフィックスで判定
        name = raw["name"].to_s
        if name.blank?
          Rails.logger.info("SS::Migration20251210000000 skip Cms::LoopSetting##{loop_setting.id}: raw['name'] is blank")
          next
        end
        if name.start_with?("スニペット/")
          attrs[:setting_type] = "snippet"
        else
          attrs[:setting_type] = "template"
        end

        loop_setting.set(attrs)
      end
    end
  end
end
