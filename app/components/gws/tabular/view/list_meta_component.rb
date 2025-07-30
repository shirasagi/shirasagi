#frozen_string_literal: true

class Gws::Tabular::View::ListMetaComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::DateTimeHelper

  attr_accessor :cur_site, :cur_user, :cur_space, :cur_form, :cur_release, :cur_view, :item
  attr_writer :columns, :id_column_map, :trash

  # Gws::Tabular.build_column_options の定義と1対1に対応した描画メソッドの定義
  # Gws::Tabular.build_column_options の定義を変更した際は、以下の描画メソッドの定義も変更すること
  FIXED_COLUMN_OPTION_RENDER_MAP = {
    # 固定の列オプション
    updated: :render_updated,
    created: :render_created,
    deleted: :render_deleted,
    updated_or_deleted: :render_updated_or_deleted,
    # ワークフローを有効にした場合に出現する列オプション
    approved: :render_approved,
    workflow_state: :render_workflow_state,
    destination_treat_state: :render_destination_treat_state,
  }.freeze

  def columns
    @columns ||= Gws::Tabular.released_columns(cur_release, site: cur_site)
  end

  def id_column_map
    @id_column_map ||= columns.index_by { |column| column.id.to_s }
  end

  def trash?
    @trash
  end

  def call
    meta_values.join.html_safe
  end

  private

  def meta_values
    ret = cur_view.meta_column_ids.map do |column_id|
      if BSON::ObjectId.legal?(column_id)
        column = id_column_map[column_id.to_s]
        next unless column

        value = item.read_tabular_value(column)
        next unless value

        renderer = column.value_renderer(value, :meta, cur_site: cur_site, cur_user: cur_user, item: item)
        next render(renderer)
      end

      render_method = FIXED_COLUMN_OPTION_RENDER_MAP[column_id.to_sym]
      next unless render_method

      send(render_method)
    end

    ret.select!(&:present?)
    ret
  end

  def render_updated
    ss_time_tag(item.updated, class: 'datetime', data: { column_id: 'updated' })
  end

  def render_created
    ss_time_tag(item.created, class: 'datetime', data: { column_id: 'created' })
  end

  def render_deleted
    ss_time_tag(item.deleted, class: 'datetime', data: { column_id: 'deleted' })
  end

  def render_updated_or_deleted
    if trash?
      render_deleted
    else
      render_updated
    end
  end

  def render_approved
    ss_time_tag(item.try(:approved), class: 'datetime', data: { column_id: 'approved' })
  end

  def render_workflow_state
    if item.respond_to?(:workflow_state)
      tag.span(t("workflow.state.#{item.workflow_state.presence || "draft"}"), data: { column_id: 'workflow_state' })
    end
  end

  def render_destination_treat_state
    if item.respond_to?(:destination_treat_state)
      tag.span(item.label(:destination_treat_state), data: { column_id: 'destination_treat_state' })
    end
  end

  def render_released
    ss_time_tag(item.try(:released), class: 'datetime', data: { column_id: 'released' })
  end

  def render_released_or_deleted
    if trash?
      render_deleted
    else
      render_released
    end
  end

  def render_release_date
    ss_time_tag(item.try(:release_date), class: 'datetime', data: { column_id: 'release_date' })
  end

  def render_close_date
    ss_time_tag(item.try(:close_date), class: 'datetime', data: { column_id: 'close_date' })
  end
end
