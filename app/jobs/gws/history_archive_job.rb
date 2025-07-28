class Gws::HistoryArchiveJob < Gws::ApplicationJob
  include Job::Gws::TaskFilter
  include SS::HistoryArchiveBase

  self.task_name = 'gws:history_archive'

  class << self
    def select_histories_to_archive(site, now = Time.zone.now)
      save_term = site.effective_log_save_days.days
      Gws::History.site(site).lt(created: threshold_day(now, save_term))
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
    @csv_generator = Gws::HistoryCsv.new(site: site, criteria: Gws::History.none).enum_csv(encoding: "UTF-8")

    all_ids = @histories.order_by(created: 1).pluck(:id)
    all_ids.each_slice(100) do |ids|
      Gws::History.in(id: ids).order_by(created: 1).to_a.each do |history|
        file = to_archive_file(history)
        append_file(file, history)
      end
    end
    @last_open_file_handle.close if @last_open_file_handle

    @last_open_file = nil
    @last_open_file_handle = nil
  end

  def csv_header
    @csv_generator.draw_header
  end

  def csv_row(history)
    @csv_generator.draw_data(history)
  end

  def create_empty_archive_file(name, filename, &block)
    Gws::HistoryArchiveFile.create_empty!(cur_site: site, name: name, filename: filename, content_type: 'application/zip', &block)
  end
end
