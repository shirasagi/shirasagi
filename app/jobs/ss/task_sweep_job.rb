class SS::TaskSweepJob < SS::ApplicationJob
  DEFAULT_KEEP_TASKS = 14.days

  def perform
    if SS.config.ss.keep_tasks && SS.config.ss.keep_tasks == '0'
      Rails.logger.info("タスクの保存期間が無期限に設定されています。")
      return
    end

    now = Time.zone.now.beginning_of_day
    if SS.config.ss.keep_tasks
      duration = SS::Duration.parse(SS.config.ss.keep_tasks)
    else
      duration = DEFAULT_KEEP_TASKS
    end
    updated = now - duration
    Rails.logger.info("#{updated.iso8601} 以降更新されていないタスクを削除します。")

    count = 0
    each_task(updated) do |task|
      if task.destroy
        count += 1
      end
    end

    Rails.logger.info("#{count.to_s(:delimited)} 件のタスクを削除しました。")
  end

  private

  def each_task(updated, &block)
    all_ids = SS::Task.all.pluck(:id)
    all_ids.each_slice(100) do |ids|
      # 注意: mongodb でソートさせるとソートバッファ不足が発生する可能性があるので、mongodb でソートさせない。
      tasks = SS::Task.all.in(id: ids).to_a
      tasks.each do |task|
        if task.updated < updated
          yield task
        end
      end
    end
  end
end
