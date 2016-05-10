module Sys::SiteCopy::Nodes
  extend ActiveSupport::Concern

  private
    @@node_fac_cat_routes = ["facility/location", "facility/category", "facility/service"]
    @@node_copied_fac_cat_routes = ["facility/search", "facility/node"]
    @@node_pg_cat_routes = ["category/node", "category/page"]

    ###
    # 元サイトから複製サイトへ以下を複製する
    #   * Cms::Node
    #     - Cms::Node の layout_id, page_layout_id はレイアウト複製時に作る @layout_records_map から取得する
    #   * Cms::Node で指定される path (ディレクトリ)
    #   * Cms::Node で指定される path 配下のファイル全て
    #
    ###
    # Cms::Node.new に必要な材料 (1レコード分)
    #   * permission_level ... 複製元と同じもの
    #   * group_ids .......... 〃
    #   * state .............. 〃
    #   * name ............... 〃
    #   * basename ........... 〃
    #   * order .............. 〃
    #   * released ........... 〃
    #   * route .............. 〃
    #   * view_route ......... 〃
    #   * shortcut ........... 〃
    #   * layout_id .......... 事前に複製しておいた Cms::Layout のID
    #   * page_layout_id ..... 〃
    #   * cur_user ........... 操作しているユーザー? (Cms::User)
    #   * cur_site ........... 複製元サイト (Cms::Site)
    #   * cur_node ........... 親となるフォルダ Cms::Node (無い場合は false)

    def copy_nodes_for_dupcms(node_fac_cats, layout_records_map)
      # 新サイト用の public 配下ディレクトリ
      # ex: /var/www/shirasagi/public/sites/h/o/s/t/n/a/m/e
      basesite_public_dir = Rails.public_path.to_s+'/sites/'+(@site_old.host.split('').join('/'))+'/_'
      site_public_dir     = Rails.public_path.to_s+'/sites/'+(@site.host.split('').join('/'))+'/_'
      @layout_records_map = layout_records_map

      # 階層の浅い物から実施
      Cms::Node.where(:site_id => @site_old.id).order('depth ASC').each do |base_cmsnode|
        next if @@node_fac_cat_routes.include?(base_cmsnode.route)
        next if @@node_copied_fac_cat_routes.include?(base_cmsnode.route)
        next if @@node_pg_cat_routes.include?(base_cmsnode.route)

        new_cmsnode_attrs = {}
        cmsnode_attr_names = [
          :permission_level, :group_ids, :state, :name, :basename, :order,
          :released, :route, :view_route, :shortcut, :filename
        ]
        cmsnode_attr_names.each do |fieldname|
          new_cmsnode_attrs[fieldname] = base_cmsnode[fieldname] if base_cmsnode[fieldname]
        end

        new_cmsnode_no_attr = {}
        new_model_attr_flag = 0
        new_model_attr = base_cmsnode.attributes.to_hash
        new_model_attr.delete("_id") if new_model_attr["_id"]
        new_model_attr.keys.each do |key|
          new_model_attr_flag = 1 if !Cms::Node.fields.keys.include?(key)
          new_cmsnode_no_attr.store(key, base_cmsnode[key]) if !Cms::Node.fields.keys.include?(key)
        end

        new_cmsnode_attrs = set_cstm_attrs(base_cmsnode, node_fac_cats, new_cmsnode_attrs)

        # レコードモデル生成
        cms_node_obj = Cms::Node.new new_cmsnode_attrs

        new_cmsnode_no_attr.each { |noattr, val| cms_node_obj[noattr] = val } if new_model_attr_flag == 1

        # 物理的なディレクトリ作成とファイル複製が必要な場合
        copy_file_dir(base_cmsnode, basesite_public_dir, site_public_dir) if ['uploader/file'].include? base_cmsnode.route

        cms_node_obj.save
      end
    end

    def copy_file_dir(base_cmsnode, basesite_public_dir, site_public_dir)
      # ディレクトリ複製
      cur_dirname   = base_cmsnode.filename
      base_dir_path = basesite_public_dir+'/'+cur_dirname
      new_dir_path  = site_public_dir+'/'+cur_dirname
      FileUtils.mkdir_p new_dir_path
      # 複製ファイルリスト, 無視名前リスト 初期化
      target_file_list = []
      ignore_name_list = ['.', '..']
      # 複製対象ファイル名リストアップ (無視対象名、存在しないモノ、ディレクトリは除外)
      Dir.exist?(base_dir_path) && Dir.entries(base_dir_path).each do |filename|
        if !ignore_name_list.include?(filename) \
          && File.exist?(base_dir_path+'/'+filename) \
          && !Dir.exist?(base_dir_path+'/'+filename)
          target_file_list << filename
        end
      end
      # 対象ファイルを全て物理複製
      target_file_list.each do |filename|
        FileUtils.cp(base_dir_path+'/'+filename, new_dir_path)
      end
    end

    def calc_cur_node(base_cmsnode)
      parent_node_depth    = base_cmsnode.depth-1
      parent_node_filename = base_cmsnode.filename.split('/').delete_at(parent_node_depth) if base_cmsnode.filename
      search_params = {
        site_id:  @site.id,
        depth:    parent_node_depth,
        filename: parent_node_filename
      }

      res_search_parent_node = Cms::Node.where(search_params)
      # if 1 < res_search_parent_node.size
      #   # logger.fatal '### 次の検索パラメータで 1 つ以上同じ Cms::Node が引っ掛かる'
      #   # logger.fatal search_params
      # end
      # 引っ掛かった親 Cms::Node の数が 1 件の場合のみ設定
      new_cmsnode_attrs[:cur_node] = res_search_parent_node.first if res_search_parent_node.size == 1
    end

    def set_cstm_attrs(base_cmsnode, node_fac_cats, new_cmsnode_attrs)
      # 施設の種類・用途・地域
      if base_cmsnode.route == "facility/page"
        new_cmsnode_attrs[:category_ids] = pase_checkboxes_for_dupcms(
          node_fac_cats, "facility/category", base_cmsnode.category_ids
        )
        new_cmsnode_attrs[:service_ids] = pase_checkboxes_for_dupcms(
          node_fac_cats, "facility/service", base_cmsnode.service_ids
        )
        new_cmsnode_attrs[:location_ids] = pase_checkboxes_for_dupcms(
          node_fac_cats, "facility/location", base_cmsnode.location_ids
        )
      end
      # 紐付くサイト
      new_cmsnode_attrs[:cur_site] = @site
      # フォルダを作成したユーザー or false
      new_cmsnode_attrs[:cur_user] = base_cmsnode.user_id ? Cms::User.find(base_cmsnode.user_id) : false
      # レイアウトID
      if base_cmsnode.layout_id && @layout_records_map[base_cmsnode.layout_id]
        new_cmsnode_attrs[:layout_id] = @layout_records_map[base_cmsnode.layout_id]
      end
      # ページレイアウトID
      if base_cmsnode.page_layout_id && @layout_records_map[base_cmsnode.page_layout_id]
        new_cmsnode_attrs[:page_layout_id] = @layout_records_map[base_cmsnode.page_layout_id]
      end
      # 親 Cms::Node 必要なら取得 (2階層以上の深さある場合)
      calc_cur_node(base_cmsnode) if base_cmsnode.cur_node && 1 < base_cmsnode.depth
      return new_cmsnode_attrs
    end

end