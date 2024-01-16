class Gws::Frames::UserNavigation::ContrastsController < ApplicationController
  include Gws::BaseFilter

  layout "ss/item_frame"
  model Gws::Contrast

  before_action :set_frame_id

  helper_method :current_contrast

  private

  def set_frame_id
    @frame_id = "user-navigation-frame"
  end

  def current_contrast
    @current_contrast ||= @model.restore_from_cookie(cookies, @cur_site)
  end

  public

  def show
    @items = @model.site(@cur_site).and_public.
      order_by(order: 1)
    render
  end

  def update
    contrast_id = params.require(:item).permit(:contrast_id)[:contrast_id]
    if contrast_id == "default"
      @model.remove_from_cookie(cookies, @cur_site)
      flash[:notice] = t('gws.notice.contrast_changed', name: t('gws.default_contrast'))
      render json: { status: 302, reload: true }, status: :ok, content_type: json_content_type
      return
    end

    if contrast_id.present?
      contrast = @model.site(@cur_site).and_public.find(contrast_id)
    end
    if contrast.blank?
      # @item.errors.add :base, :not_found_group, name: group_id
      render action: :show
      return
    end

    @model.save_in_cookie(cookies, @cur_site, contrast)
    flash[:notice] = t('gws.notice.contrast_changed', name: contrast.name)
    render json: { status: 302, reload: true }, status: :ok, content_type: json_content_type
  end
end
