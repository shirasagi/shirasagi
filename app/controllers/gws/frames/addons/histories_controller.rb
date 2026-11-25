class Gws::Frames::Addons::HistoriesController < ApplicationController
  include Gws::BaseFilter

  # model Gws::Addon::History

  layout "ss/item_frame"

  before_action :set_frame_id, :set_item

  private

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

    class_name = params[:model_class].to_s
    raise '404' unless class_name.to_s.start_with?('Gws::')

    model_class = SS.find_loaded_model(class_name)
    return unless model_class
    return unless model_class.include?(Gws::Addon::History)

    @item = model_class.site(@cur_site).find(params[:model_id]) rescue nil
    raise '404' unless @item
  end

  public

  def index
    begin
      @items = @item.histories.site(@cur_site).page(params[:page]).per(10)
    rescue
      raise '404'
    end
  end
end
