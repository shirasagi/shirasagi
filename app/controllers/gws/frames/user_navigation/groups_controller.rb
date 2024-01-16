class Gws::Frames::UserNavigation::GroupsController < ApplicationController
  include Gws::BaseFilter

  layout "ss/item_frame"
  model Gws::Group

  before_action :set_frame_id

  private

  def set_frame_id
    @frame_id = "user-navigation-frame"
  end

  public

  def show
    @item = @cur_user
    render
  end

  def update
    @item = @cur_user

    group_id = params.require(:item).permit(:group_id)[:group_id]
    if group_id.present?
      group = Gws::Group.site(@cur_site).active.find(group_id)
    end
    if group.blank?
      @item.errors.add :base, :not_found_group, name: group_id
      render action: :show
      return
    end

    @item.set_gws_default_group_id(group.id)
    result = @cur_user.save
    unless result
      render action: :show
      return
    end

    flash[:notice] = t("gws.notice.default_group_changed")
    render json: { status: 302, reload: true }, status: :ok, content_type: json_content_type
  end
end
