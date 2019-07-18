class Webmail::HistoryArchiveJob < Webmail::ApplicationJob
  include Job::SS::TaskFilter
  include SS::HistoryArchiveBase

  self.task_name = 'webmail:history_archive'

  class << self
    def select_histories_to_archive(now = Time.zone.now)
      save_term = SS.config.webmail.history['save_days']
      return Webmail::History.none if save_term.blank?
      Webmail::History.lt(created: threshold_day(now, save_term.days))
    end

    def histories_to_archive?(now = Time.zone.now)
      select_histories_to_archive(now).present?
    end
  end

  private

  def select_histories
    @histories = self.class.select_histories_to_archive
  end

  def put_histories
    @csv_generator = Webmail::History::Csv.new

    all_ids = @histories.order_by(created: 1).pluck(:id)
    all_ids.each_slice(100) do |ids|
      Webmail::History.in(id: ids).order_by(created: 1).to_a.each do |history|
        file = to_archive_file(history)
        append_file(file, history)
      end
    end
    @last_open_file_handle.close if @last_open_file_handle

    @last_open_file = nil
    @last_open_file_handle = nil
  end

  def to_archive_file(history)
    @work_dir.join(
      "year-#{history.created.strftime('%Y')}",
      "week-#{self.class.week_of_year(history.created)}",
      "#{history.created.strftime('%Y%m%d')}.csv"
    )
  end

  def create_empty_archive_file(name, filename, &block)
    Webmail::History::ArchiveFile.create_empty!(name: name, filename: filename, content_type: 'application/zip', &block)
  end
end
