class SS::Migration20251010000000
  include SS::Migration::Base

  depends_on "20250820000000"

  def change
    each_loop_setting do |loop_setting|
      updates = {}

      if loop_setting[:state].blank?
        updates[:state] = 'public'
      end

      if loop_setting[:html_format].blank?
        updates[:html_format] = 'shirasagi'
      end

      next if updates.blank?

      loop_setting.set(updates)
    end
  end

  private

  def each_loop_setting(&block)
    Cms::LoopSetting.all.each(&block)
  end
end
