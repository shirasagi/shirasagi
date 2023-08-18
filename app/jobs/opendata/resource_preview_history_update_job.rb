class Opendata::ResourcePreviewHistoryUpdateJob < Cms::ApplicationJob
  include Opendata::HistoryUpdateBase

  private

  def model
    Opendata::ResourcePreviewHistory
  end
end
