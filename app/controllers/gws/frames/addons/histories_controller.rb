class Gws::Frames::Addons::HistoriesController < ApplicationController
  include Gws::BaseFilter

  # model Gws::Addon::History

  layout "ss/item_frame"

  before_action :set_frame_id, :check_setting_user, :set_item

  private

  def setting
    @setting ||= Gws::HistoryFrameSetting.decode(params[:setting].to_s)
  rescue => e
    Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    raise SS::NotFoundError
  end

  def check_setting_user
    raise SS::ForbiddenError if setting.user_id != @cur_user.id
  end

  def set_crumbs
    set_item
    @crumbs << [t('modules.addons.gws/history'), action: :index]

    if @item
      name = @item.try(:name) || @item._id
      @crumbs << [name.to_s.truncate(20), action: :index]
    end
  end

  def set_frame_id
    @frame_id = "gws-addon-history-frame"
  end

  def set_item
    return @item if @item

    class_name = setting.model_class
    raise SS::NotFoundError unless class_name.to_s.start_with?('Gws::')

    model_class = class_name.safe_constantize
    return unless model_class
    return unless model_class.include?(Gws::Addon::History)

    @item = model_class.site(@cur_site).find(setting.model_id) rescue nil
    raise SS::NotFoundError unless @item
  end

  public

  def index
    begin
      @items = @item.histories.site(@cur_site).page(params[:page]).per(10)
    rescue
      raise SS::NotFoundError
    end
  end
end
