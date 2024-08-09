class Gws::Workflow2::Frames::DestinationStatesController < ApplicationController
  include Gws::ApiFilter

  layout "ss/item_frame"
  model Gws::Workflow2::File

  before_action :set_frame_id
  helper_method :item, :destination_treat_state_options

  private

  def set_frame_id
    @frame_id = "gws-workflow-destination-states-frame"
  end

  def items
    @items ||= @model.site(@cur_site)
  end

  def item
    @item ||= items.find(params[:id])
  end

  def destination_treat_state_options
    @destination_treat_state ||= %w(untreated treated).map do |v|
      [ I18n.t("gws/workflow2.options.destination_treat_state.#{v}"), v ]
    end
    view_context.options_for_select(@destination_treat_state, selected: item.destination_treat_state)
  end

  public

  def show
    raise "404" if item.workflow_state.blank?
    raise "404" unless %w(approve approve_without_approval).include?(item.workflow_state)
    raise "404" if !item.destination_group_ids.include?(@cur_group.id) && !item.destination_user_ids.include?(@cur_user.id)

    render
  end

  def update
    raise "404" if item.workflow_state.blank?
    raise "404" unless %w(approve approve_without_approval).include?(item.workflow_state)
    raise "404" if !item.destination_group_ids.include?(@cur_group.id) && !item.destination_user_ids.include?(@cur_user.id)

    destination_treat_state = params.require(:item).permit(:destination_treat_state)[:destination_treat_state]
    # バリデーションエラーがあっても「処理済み」にはできるようにするため #set を用いる
    item.set(destination_treat_state: destination_treat_state)

    @notice = t("gws/workflow2.notice.#{destination_treat_state}")
    render template: "show"
  end
end
