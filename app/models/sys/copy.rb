class Sys::Copy
  include ActiveModel::Model

  #app/models/concerns/sys/site_copy 以下にて記述
  include Sys::SiteCopy::Roles
  include Sys::SiteCopy::Nodes
  include Sys::SiteCopy::CmsLayout
  include Sys::SiteCopy::Checkboxes
  include Sys::SiteCopy::CmsPages
  include Sys::SiteCopy::CmsParts

  include Sys::SiteCopy::Article
  include Sys::SiteCopy::Files
  include Sys::SiteCopy::Templates
  include Sys::SiteCopy::Dictionaries

  attr_accessor :name, :host, :domains, :copy_site, :copy_contents

  #NOTE: 以下だとバリデーションが働かなかった
  validates :name, presence: true
  validates :host, presence: true
  validates :domains, presence: true
  validates :copy_site, presence: true

  @@node_fac_cat_routes = ["facility/location", "facility/category", "facility/service"]
  @@node_copied_fac_cat_routes = ["facility/search", "facility/node"]
  @@node_pg_cat_routes = ["category/node", "category/page"]

  def run_copy(params)
    @site_old = Cms::Site.find(params["@copy_run"]["copy_site"])
    @site = Cms::Site.create({
                              group_ids:  @site_old.group_ids,
                              name:       params["@copy_run"]["name"],
                              host:       params["@copy_run"]["host"],
                              domains:    params["@copy_run"]["domains"]
                            })

    copy_roles

    #必須コピー：フォルダー、固定ページ、レイアウト、パーツ
    @layout_records_map = {}
    @layout_records_map = copy_cms_layout
    #チェックボックス（「施設の種類」「施設の用途」「施設地域」）
    node_fac_cats = copy_checkboxes_for_dupcms(@@node_fac_cat_routes)
    def_fac_checkboxes_for_dupcms(node_fac_cats)
    #チェックボックス（カテゴリー）
    node_pg_cats = copy_checkboxes_for_dupcms(@@node_pg_cat_routes)
    #フォルダ (uploader/file 配下で管理?するファイル含む)
    copy_nodes_for_dupcms(node_fac_cats, @layout_records_map)
    copy_cms_pages
    copy_cms_parts

    #選択コピー：記事・その他ページ、共有ファイル、テンプレート、かな辞書
    copy_article(node_pg_cats, @layout_records_map) if params["@copy_run"]["article"] == "1"
    create_dupfiles_for_dupsite if params["@copy_run"]["files"] == "1"
    copy_templates if params["@copy_run"]["editor_templates"] == "1"
    copy_dictionaries if params["@copy_run"]["dictionaries"] == "1"
  end
end
