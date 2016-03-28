class Sys::CopyController < ApplicationController
  include Sys::BaseFilter

#app/controllers/concerns/sys 以下にて記述
  include Sys::SiteCopyValid

  include Sys::SiteCopyParts

  include Sys::SiteCopyRoles
  include Sys::SiteCopyCmsLayout
  include Sys::SiteCopyCheckboxes
  include Sys::SiteCopyCmsPages
  include Sys::SiteCopyCmsParts

  include Sys::SiteCopyArticle
  include Sys::SiteCopyFiles
  include Sys::SiteCopyTemplates
  include Sys::SiteCopyDictionaries

  private
    @@node_fac_cat_routes = ["facility/location", "facility/category", "facility/service"]
    @@node_copied_fac_cat_routes = ["facility/search", "facility/node"]
    @@node_pg_cat_routes = ["category/node", "category/page"]

    def set_crumbs
      @crumbs << [:"sys.copy", sys_copy_path]
    end

  public
    def index
      @copy  = Sys::Copy.new
      @items = []
      render :action => 'index'
    end

    def confirm
      chk_valid
    end

    def run
      Thread.start do
        site_old = Cms::Site.find(params["@copy_run"]["copy_site"])
        site = Cms::Site.create({
                                  group_ids:  site_old.group_ids,
                                  name:       params["@copy_run"]["name"],
                                  host:       params["@copy_run"]["host"],
                                  domains:    params["@copy_run"]["domains"]
                                })
        _copy_roles(site_old, site)

#必須コピー：フォルダー、固定ページ、レイアウト、パーツ
        @layout_records_map = {}
        _copy_cms_layout(site_old, site)
        #チェックボックス（「施設の種類」「施設の用途」「施設地域」）
        node_fac_cats = _copy_checkboxes_for_dupcms(site_old, site, @@node_fac_cat_routes)
        _def_fac_checkboxes_for_dupcms(site_old, site, node_fac_cats)
        #チェックボックス（カテゴリー）
        node_pg_cats = _copy_checkboxes_for_dupcms(site_old, site, @@node_pg_cat_routes)
        #フォルダ (uploader/file 配下で管理?するファイル含む)
        _copy_nodes_for_dupcms(site_old, site, node_fac_cats)
        _copy_cms_pages(site_old, site)
        _copy_cms_parts(site_old, site)

#選択コピー：記事・その他ページ、共有ファイル、テンプレート、かな辞書
        _copy_article(site_old, site, node_pg_cats) if params["@copy_run"]["article"] == "1"
        _create_dupfiles_for_dupsite(site_old, site) if params["@copy_run"]["files"] == "1"
        _copy_templates(site_old, site) if params["@copy_run"]["editor_templates"] == "1"
        _copy_dictionaries(site_old, site) if params["@copy_run"]["dictionaries"] == "1"

      end
    end
end
