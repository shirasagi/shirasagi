class SS::Migration20251023000000
  include SS::Migration::Base

  depends_on "20250820000000"

  def change
    Cms::LoopSetting.all.find_each(batch_size: 1_000) do |loop_setting|
      raw = loop_setting.attributes
      attrs = {}
      attrs[:html_format] = "shirasagi" if raw["html_format"].blank?
      attrs[:state] = "public" if raw["state"].blank?
      attrs[:loop_html_setting_type] = "template" if raw["loop_html_setting_type"].blank?
      next if attrs.blank?

      loop_setting.set(attrs)
    end
  end
end
