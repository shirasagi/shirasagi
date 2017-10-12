class Gws::Circular::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Circular::MarkFilter

  before_action :set_selected_items, only: [:destroy_all, :disable_all, :mark_all, :unmark_all, :download]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/circular'), gws_circular_topics_path]
  end

  public

  def show
    if @item.mark_type == 'simple' && @item.markable?(@cur_user)
      @item.mark_by(@cur_user).save
    end
    raise '403' unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def mark_all
    @items.each{ |item| item.mark_by(@cur_user).save if item.markable?(@cur_user) }
    render_destroy_all(false)
  end

  def unmark_all
    @items.each{ |item| item.unmark_by(@cur_user).save if item.unmarkable?(@cur_user) }
    render_destroy_all(false)
  end

  def download
    raise '403' unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    csv = @items.
        order(updated: -1).
        to_csv.
        encode('SJIS', invalid: :replace, undef: :replace)

    send_data csv, filename: "circular_#{Time.zone.now.to_i}.csv"
  end
end
