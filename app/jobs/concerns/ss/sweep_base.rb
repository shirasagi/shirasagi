module SS::SweepBase
  extend ActiveSupport::Concern
  DEFAULT_KEEP_TASKS = 14.days

  def model
  end

  def model_name
    model.model_name.human
  end

  def keep_duration
  end

  def perform
    if keep_duration && keep_duration == '0'
      Rails.logger.info("#{model_name}の保存期間が無期限に設定されています。")
      return
    end

    now = Time.zone.now.beginning_of_day
    if keep_duration
      duration = SS::Duration.parse(SS.config.ss.keep_tasks)
    else
      duration = DEFAULT_KEEP_TASKS
    end
    updated = now - duration
    Rails.logger.info("#{updated.iso8601} 以降更新されていない#{model_name}を削除します。")

    count = 0
    each_items(updated) do |item|
      p item.id
      if item.destroy
        count += 1
      end
    end

    Rails.logger.info("#{count.to_fs(:delimited)} 件の#{model_name}を削除しました。")
  end

  private

  def each_items(updated, &block)
    all_ids = model.all.pluck(:id)
    all_ids.each_slice(100) do |ids|
      # 注意: mongodb でソートさせるとソートバッファ不足が発生する可能性があるので、mongodb でソートさせない。
      items = model.all.in(id: ids).to_a
      items.each do |item|
        if item.updated < updated
          yield item
        end
      end
    end
  end
end
