#frozen_string_literal: true

class Gws::Tabular::View::ListTitleComponent < ApplicationComponent
  include ActiveModel::Model

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

  def title
    ret = title_values.join(" ").html_safe
    ret = item.id.to_s if ret.blank?
    ret
  end

  def call
    link_to(title, url_for(action: :show, id: item), class: "title")
  end

  private

  def title_values
    ret = cur_view.title_column_ids.map do |title_column_id|
      if BSON::ObjectId.legal?(title_column_id)
        title_column = id_column_map[title_column_id.to_s]
        next unless title_column

        value = item.read_tabular_value(title_column)
        next unless value

        renderer = title_column.value_renderer(value, :title, cur_site: cur_site, cur_user: cur_user, item: item)
        next render(renderer)
      end

      render_method = FIXED_COLUMN_OPTION_RENDER_MAP[title_column_id.to_sym]
      next unless render_method

      send(render_method)
    end

    ret.select!(&:present?)
    ret
  end

  def render_updated
    I18n.l(item.updated, format: :picker)
  end

  def render_created
    I18n.l(item.created, format: :picker)
  end

  def render_deleted
    I18n.l(item.deleted, format: :picker)
  end

  def render_updated_or_deleted
    if trash?
      render_deleted
    else
      render_updated
    end
  end

  def render_approved
    approved = item.try(:approved)
    if approved
      I18n.l(approved, format: :picker)
    end
  end

  def render_workflow_state
    if item.respond_to?(:workflow_state)
      I18n.t("workflow.state.#{item.workflow_state.presence || "draft"}")
    end
  end

  def render_destination_treat_state
    if item.respond_to?(:destination_treat_state)
      item.label(:destination_treat_state)
    end
  end

  def render_released
    released = item.try(:released)
    if released
      I18n.l(released, format: :picker)
    end
  end

  def render_released_or_deleted
    if trash?
      render_deleted
    else
      render_released
    end
  end

  def render_release_date
    release_date = item.try(:release_date)
    if release_date
      I18n.l(release_date, format: :picker)
    end
  end

  def render_close_date
    close_date = item.try(:close_date)
    if close_date
      I18n.l(close_date, format: :picker)
    end
  end
end
