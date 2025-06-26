class Gws::Tabular::Frames::Gws::LookupColumnsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Tabular::Column

  helper_method :target_columns

  private

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def forms
    @forms ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.reorder(order: 1, id: 1)
    end
  end

  def cur_form
    @cur_form ||= forms.find(params[:form])
  end

  def target_form
    @target_form ||= begin
      column_id = params.require(:item).permit(:column_id)[:column_id].to_s.presence

      cur_columns = Gws::Column::Base.site(@cur_site)
      cur_columns = cur_columns.form(cur_form)
      cur_column = cur_columns.find(column_id)

      target_form = cur_column.try(:reference_form)
      raise "404" if target_form.blank?

      target_form
    end
  end

  def target_columns
    @target_columns ||= begin
      columns = Gws::Column::Base.site(@cur_site)
      columns = columns.form(target_form)
      columns = columns.reorder(order: 1, id: 1)
      columns = columns.only(:id, :name)
      columns.to_a
    end
  end

  public

  def index
    target_columns
    render layout: false
  end
end
