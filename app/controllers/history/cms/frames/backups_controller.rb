class History::Cms::Frames::BackupsController < ApplicationController
  include Cms::ApiFilter

  layout "ss/item_frame"
  model History::Backup

  helper_method :setting, :ref_item

  private

  def setting
    @setting ||= History::BackupFrameSetting.decode(params[:setting].to_s)
  rescue JSON::JWT::Exception, JSON::ParserError, ArgumentError => e
    Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    raise SS::NotFoundError
  end

  def ref_item
    @ref_item ||= begin
      raise SS::NotFoundError if setting.ref_class.blank? || setting.ref_id.blank?

      model = setting.ref_class.constantize
      criteria = model.all
      criteria = criteria.site(@cur_site) if criteria.respond_to?(:site)
      criteria.find(setting.ref_id)
    end
  end

  def set_items
    @items ||= History::Backup.all.where(ref_coll: ref_item.collection_name, ref_id: setting.ref_id)
  end

  public

  def index
    raise "403" if ref_item.respond_to?(:allowed?) && !ref_item.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    @items = @items.reorder(id: -1)
    render
  end
end
