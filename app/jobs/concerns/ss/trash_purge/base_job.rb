module SS::TrashPurge::BaseJob
  extend ActiveSupport::Concern

  DEFAULT_THRESHOLD_YEARS = 1

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
    threshold ||= site.trash_threshold
    return now - DEFAULT_THRESHOLD_YEARS.days if threshold.blank?
    unit = site.trash_threshold_unit.presence || 'years'

    case threshold
    when Integer
      return now - threshold.send(unit)
    when String
      term, unit = threshold.split('.')
      if unit.blank?
        return now - Integer(threshold).days
      end

      case unit.singularize.downcase
      when 'day'
        now - Integer(term).days
      when 'week'
        now - Integer(term).weeks
      when 'month'
        now - Integer(term).months
      when 'year'
        now - Integer(term).years
      else
        raise ArgumentError, "invalid value for threshold: \"#{threshold}\""
      end
    else
      raise ArgumentError, "invalid value for threshold: \"#{threshold}\""
    end
  end

  def set_items
    @items = model.site(site).only_deleted(@threshold)
  end
end
