class Gws::Tabular::MainsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Tabular::File

  navi_view "gws/tabular/main/navi"

  private

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.only(:id, :i18n_name, :site_id)
      item = criteria.find(params[:space])
      item.site = item.cur_site = @cur_site
      item
    end
  end

  def forms
    @forms ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.only(:id, :i18n_name, :site_id, :space_id)
      criteria.reorder(order: 1, id: 1)
    end
  end

  def views
    @views ||= begin
      criteria = Gws::Tabular::View::Base.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.in(form_id: forms.pluck(:id))
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.only(:id, :i18n_name, :site_id, :space_id, :form_id)
      criteria.reorder(order: 1, id: 1)
    end
  end

  def default_view
    return @default_view if instance_variable_defined?(:@default_view)
    @default_view = views.and_default.first
  end

  def set_item
  end

  public

  def show
    if forms.blank?
      head :not_found
      return
    end

    if default_view.present?
      redirect_to gws_tabular_files_path(space: cur_space, form: default_view.form, view: default_view)
      return
    end

    default_form = forms.first
    default_form_view = views.form(default_form).first
    if default_form_view
      redirect_to gws_tabular_files_path(space: cur_space, form: default_form, view: default_form_view)
      return
    end

    redirect_to gws_tabular_files_path(space: cur_space, form: default_form, view: '-')
  end
end
