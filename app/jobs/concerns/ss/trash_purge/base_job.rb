module SS::TrashPurge::BaseJob
  extend ActiveSupport::Concern

  included do
    cattr_accessor :model
    before_perform :parse_arguments
    before_perform :set_items
  end

  def perform(*_)
    count = @items.destroy_all
    Rails.logger.info "#{I18n.l(@threshold.to_date)}以前の#{model.model_name.human}を#{count}件削除しました。"
  end

  private

  def parse_arguments
    options = arguments.dup.extract_options!
    @threshold = parse_threshold(options[:now] || Time.zone.now, options[:threshold])
  end

  def parse_threshold(now, threshold)
    SS.parse_threshold!(now, threshold, site: site)
  end

  def set_items
    @items = model.site(site).only_deleted(@threshold)
  end
end
