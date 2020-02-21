class Gws::Notice::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Notice::Folder

  navi_view "gws/notice/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_notice_label || t('modules.gws/notice'), gws_notice_main_path]
    @crumbs << [Gws::Notice::Folder.model_name.human, gws_notice_folders_path]
  end

  def pre_params
    ret = {}
    SS.config.gws.notice['default_notice_individual_body_size_limit'].tap do |limit|
      if limit.present?
        ret[:notice_individual_body_size_limit] = limit
      end
    end
    SS.config.gws.notice['default_notice_total_body_size_limit'].tap do |limit|
      if limit.present?
        ret[:notice_total_body_size_limit] = limit
      end
    end
    SS.config.gws.notice['default_notice_individual_file_size_limit'].tap do |limit|
      if limit.present?
        ret[:notice_individual_file_size_limit] = limit
      end
    end
    SS.config.gws.notice['default_notice_total_file_size_limit'].tap do |limit|
      if limit.present?
        ret[:notice_total_file_size_limit] = limit
      end
    end
    ret
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    @items = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
  end

  def move
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.attributes = get_params
    render_update @item.save, notice: t("ss.notice.moved")
  end

  def reclaim
    set_item

    @item.reclaim!
    redirect_to({ action: :show }, { notice: t("gws/notice.notice.reclaimed") })
  end
end
