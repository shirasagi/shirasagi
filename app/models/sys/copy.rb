class Sys::Copy
  include ActiveModel::Model

#app/models/concerns/sys/site_copy 以下にて記述
  include Sys::SiteCopyRoles
  include Sys::SiteCopyNodes
  include Sys::SiteCopyCmsLayout
  include Sys::SiteCopyCheckboxes
  include Sys::SiteCopyCmsPages
  include Sys::SiteCopyCmsParts

  include Sys::SiteCopyArticle
  include Sys::SiteCopyFiles
  include Sys::SiteCopyTemplates
  include Sys::SiteCopyDictionaries

  attr_accessor :name, :host, :domains, :copy_site, :copy_contents

  #NOTE: 以下だとバリデーションが働かなかった
  validates :name, presence: true
  validates :host, presence: true
  validates :domains, presence: true
  validates :copy_site, presence: true

  @@node_fac_cat_routes = ["facility/location", "facility/category", "facility/service"]
  @@node_copied_fac_cat_routes = ["facility/search", "facility/node"]
  @@node_pg_cat_routes = ["category/node", "category/page"]

  def self.run_copy(params)
    site_old = Cms::Site.find(params["@copy_run"]["copy_site"])
    site = Cms::Site.create({
                              group_ids:  site_old.group_ids,
                              name:       params["@copy_run"]["name"],
                              host:       params["@copy_run"]["host"],
                              domains:    params["@copy_run"]["domains"]
                            })
    Sys::SiteCopyRoles.copy_roles(site_old, site)

#必須コピー：フォルダー、固定ページ、レイアウト、パーツ
    @layout_records_map = {}
    @layout_records_map = Sys::SiteCopyCmsLayout.copy_cms_layout(site_old, site)
    #チェックボックス（「施設の種類」「施設の用途」「施設地域」）
    node_fac_cats = Sys::SiteCopyCheckboxes.copy_checkboxes_for_dupcms(site_old, site, @@node_fac_cat_routes)
    Sys::SiteCopyCheckboxes.def_fac_checkboxes_for_dupcms(site_old, site, node_fac_cats)
    #チェックボックス（カテゴリー）
    node_pg_cats = Sys::SiteCopyCheckboxes.copy_checkboxes_for_dupcms(site_old, site, @@node_pg_cat_routes)
    #フォルダ (uploader/file 配下で管理?するファイル含む)
    Sys::SiteCopyNodes.copy_nodes_for_dupcms(site_old, site, node_fac_cats, @layout_records_map)
    Sys::SiteCopyCmsPages.copy_cms_pages(site_old, site)
    Sys::SiteCopyCmsParts.copy_cms_parts(site_old, site)

#選択コピー：記事・その他ページ、共有ファイル、テンプレート、かな辞書
    Sys::SiteCopyArticle.copy_article(site_old, site, node_pg_cats, @layout_records_map) if params["@copy_run"]["article"] == "1"
    Sys::SiteCopyFiles.create_dupfiles_for_dupsite(site_old, site) if params["@copy_run"]["files"] == "1"
    Sys::SiteCopyTemplates.copy_templates(site_old, site) if params["@copy_run"]["editor_templates"] == "1"
    Sys::SiteCopyDictionaries.copy_dictionaries(site_old, site) if params["@copy_run"]["dictionaries"] == "1"

  end
end
