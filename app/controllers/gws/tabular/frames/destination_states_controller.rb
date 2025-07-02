class Gws::Tabular::Frames::DestinationStatesController < ApplicationController
  include Gws::ApiFilter

  layout "ss/item_frame"
  model Gws::Tabular::File

  before_action :set_frame_id
  helper_method :item, :destination_treat_state_options

  private

  def set_frame_id
    @frame_id = "gws-workflow-destination-states-frame"
  end

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def forms
    @forms ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.reorder(order: 1, id: 1)
    end
  end

  def cur_form
    @cur_form ||= begin
      form = forms.find(params[:form])
      form.site = form.cur_site = @cur_site
      form.space = form.cur_space = cur_space
      form
    end
  end

  def cur_release
    @cur_release ||= begin
      release = cur_form.current_release
      raise "404" unless release
      release
    end
  end

  def set_model
    @model = Gws::Tabular::File[cur_release]
  end

  def items
    @items ||= @model.site(@cur_site)
  end

  def item
    @item ||= begin
      item = items.find(params[:id])
      item.site = item.cur_site = @cur_site
      item.space = item.cur_space = cur_space
      item.form = item.cur_form = cur_form
      item
    end
  end

  def destination_treat_state_options
    @destination_treat_state ||= %w(untreated treated).map do |v|
      [ I18n.t("gws/workflow.options.destination_treat_state.#{v}"), v ]
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

    destination_treat_state = params.expect(item: [:destination_treat_state])[:destination_treat_state]
    # バリデーションエラーがあっても「処理済み」にはできるようにするため #set を用いる
    item.set(destination_treat_state: destination_treat_state)

    @notice = t("gws/workflow.notice.#{destination_treat_state}")
    render template: "show"
  end
end
