class Opendata::ResourceDownloadHistoryUpdateJob < Cms::ApplicationJob
  include Opendata::HistoryUpdateBase

  private

  def model
    Opendata::ResourceDownloadHistory
  end
end
