class Sys::HistoryArchiveJob < SS::ApplicationJob
  include Job::SS::TaskFilter
  include SS::HistoryArchiveBase

  self.task_name = 'sys:history_archive'

  class << self
    def select_histories_to_archive(site, now = Time.zone.now)
      save_term = SS.config.ss.history_log_saving_days
      History::Log.lt(created: DateTime.now - 1.second)
    end

    def histories_to_archive?(site, now = Time.zone.now)
      select_histories_to_archive(site, now).present?
    end
  end

  private

  def select_histories
    @histories = self.class.select_histories_to_archive(site)
  end

  def put_histories
    @csv_generator = Sys::HistoryCsv.new(cur_site: site)

    all_ids = @histories.order_by(created: 1).pluck(:id)
    all_ids.each_slice(100) do |ids|
      History::Log.where(site_id: nil).in(id: ids).order_by(created: 1).to_a.each do |history|
        file = to_archive_file(history)
        append_file(file, history)
      end

      if site
        History::Log.site(site).in(id: ids).order_by(created: 1).to_a.each do |history|
          file = to_archive_file(history)
          append_file(file, history)
        end
      end
    end
    @last_open_file_handle.close if @last_open_file_handle

    @last_open_file = nil
    @last_open_file_handle = nil
  end

  def create_empty_archive_file(name, filename, &block)
    Sys::HistoryArchiveFile.create_empty!(cur_site: site, name: name, filename: filename, content_type: 'application/zip', &block)
  end
end
