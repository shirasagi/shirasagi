class Opendata::ResourceDownloadHistoryArchiveJob < Cms::ApplicationJob
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

    @histories0 = Opendata::ResourceDownloadHistory.site(site).lt(downloaded: threshold_day)
    @histories1 = Opendata::ResourceDatasetDownloadHistory.site(site).lt(downloaded: threshold_day)
    @histories2 = Opendata::ResourceBulkDownloadHistory.site(site).lt(downloaded: threshold_day)
  end

  def destroy_histories
    @histories0.destroy_all if @histories0
    @histories1.destroy_all if @histories1
    @histories2.destroy_all if @histories2
  end

  def put_histories
    @csv_generator = Opendata::ResourceDownloadHistory::HistoryCsv.new(cur_site: site)

    [ @histories0, @histories1, @histories2 ].each do |criteria|
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(100) do |ids|
        criteria.in(id: ids).to_a.each do |history|
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
    Opendata::ResourceDownloadHistory::ArchiveFile.create_empty!(
      cur_site: site, name: name, filename: filename, content_type: 'application/zip', &block
    )
  end
end
