class Opendata::ResourcePreviewHistoryArchiveJob < Cms::ApplicationJob
  include SS::HistoryArchiveBase

  class << self
    def effective_save_days
      SS.config.opendata.history['save_days'].presence || 14
    end
  end

  private

  def select_histories
    now = @options[:now].try { |time| Time.zone.parse(time) } || Time.zone.now
    threshold_day = self.class.threshold_day(now, self.class.effective_save_days.days)

    @histories = Opendata::ResourcePreviewHistory.site(site).lt(previewed: threshold_day)
  end

  def put_histories
    @csv_generator = Opendata::ResourcePreviewHistory::HistoryCsv.new(cur_site: site)

    all_ids = @histories.pluck(:id)
    all_ids.each_slice(100) do |ids|
      @histories.in(id: ids).to_a.each do |history|
        file = to_archive_file(history)
        append_file(file, history)
      end
    end
    @last_open_file_handle.close if @last_open_file_handle

    @last_open_file = nil
    @last_open_file_handle = nil
  end

  def create_empty_archive_file(name, filename, &block)
    Opendata::ResourcePreviewHistory::ArchiveFile.create_empty!(
      cur_site: site, name: name, filename: filename, content_type: 'application/zip', &block
    )
  end
end
