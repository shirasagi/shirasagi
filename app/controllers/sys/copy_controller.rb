class Sys::CopyController < ApplicationController
  include Sys::BaseFilter

  private
    @@node_fac_cat_routes = ["facility/location", "facility/category", "facility/service"]
    @@node_copied_fac_cat_routes = ["facility/search", "facility/node"]
    @@node_pg_cat_routes = ["category/node", "category/page"]

    def set_crumbs
      @crumbs << [:"sys.copy", sys_copy_path]
    end

    ###
    # 元サイトから複製サイトへ、共有ファイルを複製する。
    # @param  {Cms::Site} base_site_model_obj
    # @param  {Cms::Site} new_site_model_obj
    ###
    def _create_dupfiles_for_dupsite(base_site_model_obj, new_site_model_obj)
      if !base_site_model_obj.kind_of?(Cms::Site) || !new_site_model_obj.kind_of?(Cms::Site)
        logger.fatal 'Expected the 2 arguments. - [0] => Cms::Site, [1] => Cms::Site'
        return false
      end
      # 元サイトに紐付く共有ファイルを取得.
      # JSON ライクに取り扱いたいので配列化.
      old_file_model_list = Cms::File.where(:site_id => base_site_model_obj._id).to_a

      old_file_model_list.each do |base_file_model_obj|
        # ファイルModelを生成
        new_file_model_obj = _copy_cmsfile_for_dupcms(base_file_model_obj, new_site_model_obj)
        # 元ファイルModelに VirtualAttribute が含まれる場合, それも複製Modelへ追加
        base_file_model_obj.attributes.keys.each do |base_obj_field|
          next if %w(id _id created updated).include? base_obj_field # 余計なものは飛ばす
          new_file_model_obj[base_obj_field] = base_file_model_obj[base_obj_field] if !Cms::File.fields.keys.include? base_obj_field
        end
        # 複製した添付ファイルの実体とModelを保存
        if !new_file_model_obj.save_files
            # 保存に失敗
            logger.fatal new_file_model_obj.errors.full_messages
        end
      end # end / old_file_model_list.each

    end

    ###
    # 複製元サイトのファイルModelを複製し、複製サイトへ紐付けた状態で生成する
    # @param  {Cms::File} base_file_model_obj
    # @param  {Cms::Site} new_site_model_obj
    # @return {Cms::File}
    ###
    def _copy_cmsfile_for_dupcms(base_file_model_obj, new_site_model_obj)
      psude_params = {
        :in_files         => [_gen_dup_tmpfile(base_file_model_obj)],
        :permission_level => base_file_model_obj.permission_level,
        :group_ids        => base_file_model_obj.group_ids,
        :cur_user         => Cms::User.find(base_file_model_obj.user_id),
        :cur_site         => new_site_model_obj
      }
      Cms::File.new psude_params
    end

    ###
    # 元ファイルから新規テンポラリファイルを作成
    # @param  {Cms::File} base_file_model_obj
    # @return {ActionDispatch::Http::UploadedFile}
    ###
    def _gen_dup_tmpfile(base_file_model_obj)
        base_file_data = File.open(base_file_model_obj.path, 'r+b')
        tmp_file_obj   = Tempfile.new(base_file_model_obj.filename)
        IO.copy_stream(base_file_data, tmp_file_obj)
        base_file_hash = {
          :tempfile => tmp_file_obj,
          :filename => base_file_model_obj.filename,
          :type     => base_file_model_obj.content_type,
          :head     => "Content-Disposition: form-data; name=\"item[in_files][]\"; filename=\"#{base_file_model_obj.filename}\"\r\nContent-Type: #{base_file_model_obj.content_type}\r\n"
        }
        ActionDispatch::Http::UploadedFile.new(base_file_hash)
    end

    ###
    # 元サイトから複製サイトへ以下を複製する
    #   * Cms::Node
    #     - Cms::Node の layout_id, page_layout_id はレイアウト複製時に作る @layout_records_map から取得する
    #   * Cms::Node で指定される path (ディレクトリ)
    #   * Cms::Node で指定される path 配下のファイル全て
    #
    # @param  {Cms::Site} base_site
    # @param  {Cms::Site} new_site
    ###
    def _copy_nodes_for_dupcms(base_site, new_site, node_fac_cats)
      if !base_site.kind_of?(Cms::Site) || !new_site.kind_of?(Cms::Site)
        logger.fatal 'Expected 2 arguments. - [0] => Cms::Site, [1] => Cms::Site'
        return false
      end

      # 新サイト用の public 配下ディレクトリ
      # ex: /var/www/shirasagi/public/sites/h/o/s/t/n/a/m/e
      basesite_public_dir = Rails.public_path.to_s+'/sites/'+(base_site.host.split('').join('/'))+'/_'
      site_public_dir     = Rails.public_path.to_s+'/sites/'+(new_site.host.split('').join('/'))+'/_'
# logger.fatal '>>> basesite_public_dir = '+site_public_dir
# logger.fatal '>>> site_public_dir = '+site_public_dir

      # 階層の浅い物から実施
      Cms::Node.where(:site_id => base_site.id).order('depth ASC').each do |base_cmsnode|
        if @@node_fac_cat_routes.include?(base_cmsnode.route)
            next
        end
        if @@node_copied_fac_cat_routes.include?(base_cmsnode.route)
            next
        end
        if @@node_pg_cat_routes.include?(base_cmsnode.route)
            next
        end

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
        new_cmsnode_attrs = {}
        cmsnode_attr_names = [
          :permission_level,
          :group_ids,
          :state,
          :name,
          :basename,
          :order,
          :released,
          :route,
          :view_route,
          :shortcut,
          :filename
        ]
        cmsnode_attr_names.each do |fieldname|
          new_cmsnode_attrs[fieldname] = base_cmsnode[fieldname] if base_cmsnode[fieldname]
        end

        new_cmsnode_no_attr = {}
        new_model_attr_flag = 0
        new_model_attr = base_cmsnode.attributes.to_hash
        new_model_attr.delete("_id") if new_model_attr["_id"]
        new_model_attr.keys.each do |key|
          if !Cms::Node.fields.keys.include?(key)
            new_model_attr_flag = 1
            new_cmsnode_no_attr.store(key, base_cmsnode[key])
          end
        end

        # 施設の種類・用途・地域
        if base_cmsnode.route == "facility/page"
          new_cmsnode_attrs[:category_ids] = _pase_checkboxes_for_dupcms(node_fac_cats, "facility/category", base_cmsnode.category_ids)
          new_cmsnode_attrs[:service_ids]  = _pase_checkboxes_for_dupcms(node_fac_cats, "facility/service", base_cmsnode.service_ids)
          new_cmsnode_attrs[:location_ids] = _pase_checkboxes_for_dupcms(node_fac_cats, "facility/location", base_cmsnode.location_ids)
        end
        # 紐付くサイト
        new_cmsnode_attrs[:cur_site] = new_site
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
        if base_cmsnode.cur_node && 1 < base_cmsnode.depth
          parent_node_depth    = base_cmsnode.depth-1
          parent_node_filename = base_cmsnode.filename.split('/').delete_at(parent_node_depth) if base_cmsnode.filename
          search_params = {
            site_id:  new_site.id,
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

        # レコードモデル生成
        cms_node_obj = Cms::Node.new new_cmsnode_attrs

        if new_model_attr_flag == 1
          new_cmsnode_no_attr.each do |noattr, val|
              cms_node_obj[noattr] = val
          end
        end

        # 物理的なディレクトリ作成とファイル複製が必要な場合
        if ['uploader/file'].include? base_cmsnode.route
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
            if !ignore_name_list.include?(filename) && File.exist?(base_dir_path+'/'+filename) && !Dir.exist?(base_dir_path+'/'+filename)
              target_file_list << filename
            end
          end
          # 対象ファイルを全て物理複製
          target_file_list.each do |filename|
            FileUtils.cp(base_dir_path+'/'+filename, new_dir_path)
          end
        end

        if !cms_node_obj.save
          # 保存失敗
          logger.fatal cms_node_obj.errors.full_messages
          logger.fatal cms_node_obj.attributes
          return false
        end
      end
    end

#広告バナー
    def _create_dup_banner_for_dup_site(site_old, site)
      if !site_old.kind_of?(Cms::Site) || !site.kind_of?(Cms::Site)
        logger.fatal 'Expected 2 arguments. - [0] => Cms::Site, [1] => Cms::Site'
        return false
      end
      cms_ads = Ads::Banner.where(site_id: site_old.id).where(route: "ads/banner").order('depth ASC')
      cms_ads.each do |cms_ad|
          new_cms_ad = Ads::Banner.new
           # 基本項目の情報コピー
          new_cms_ad.attributes do |key, value|
            if key =~ /^(_id)$/ # コピー非対象項目のフィルタリング
              next
            end
            new_cms_ad[:key] = value
          end
          # その他項目のコピーと編集
          new_cms_ad.site_id = site.id
          new_cms_ad.name = cms_ad.name
          new_cms_ad.filename = cms_ad.filename
          new_cms_ad.link_url = cms_ad.link_url
          new_cms_ad.file_id  = _clone_file(cms_ad.file_id)
          if cms_ad.layout_id && @layout_records_map[cms_ad.layout_id]
            new_cms_ad.layout_id = @layout_records_map[cms_ad.layout_id]
          end

          new_cms_ad.save!
        end
    end

#施設写真
    def _create_dup_facility_for_dup_site(site_old, site)
        cms_facilities = Facility::Image.where(site_id: site_old.id).where(route: "facility/image")
        cms_facilities.each do |cms_facility|
          new_cms_facility = Facility::Image.new
          # 基本項目の情報コピー
          new_cms_facility.attributes do |key, value|
            if key =~ /^(_id)$/
              next
            end
            new_cms_facility[:key] = value
          end
          # その他項目のコピーと編集
          new_cms_facility.site_id = site.id
          new_cms_facility.name = cms_facility.name
          new_cms_facility.filename = cms_facility.filename
          new_cms_facility.layout_id = cms_facility.layout_id #TODO:コピーしたレイアウトIDを適用
          new_cms_facility.image_id = _clone_file(cms_facility.image_id)
          if cms_facility.layout_id && @layout_records_map[cms_facility.layout_id]
            new_cms_facility.layout_id = @layout_records_map[cms_facility.layout_id]
          end
          new_cms_facility.save!
        end
    end

#キービジュアル
    def _create_dup_key_visuals_for_dup_site(site_old, site)
        cms_key_visuals = KeyVisual::Image.where(site_id: site_old.id).where(route: "key_visual/image")
        cms_key_visuals.each do |cms_key_visual|
            new_cms_key_visual_no_attr = {}
            new_model_attr_flag = 0
            new_model_attr = cms_key_visual.attributes.to_hash
            new_model_attr.delete("_id") if new_model_attr["_id"]
            new_model_attr.keys.each do |key|
                if !KeyVisual::Image.fields.keys.include?(key)
                    new_model_attr_flag = 1
                    new_cms_key_visual_no_attr.store(key, cms_key_visual[key])
                    new_model_attr.delete("#{key}")
                end
            end
            new_cms_key_visual = KeyVisual::Image.new(new_model_attr)
            new_cms_key_visual.site_id = site.id

            if new_model_attr_flag == 1
              new_cms_key_visual_no_attr.each do |noattr, val|
                new_cms_key_visual[noattr] = val
              end
            end

            new_cms_key_visual.file_id = _clone_file(cms_key_visual.file_id)
            if cms_key_visual.layout_id && @layout_records_map[cms_key_visual.layout_id]
              new_cms_key_visual.layout_id = @layout_records_map[cms_key_visual.layout_id]
            end

            new_cms_key_visual.save!
          end
    end

#その他の記事・その他ページ
    def _create_dup_cms_page2_for_dup_site(site_old, site, node_pg_cats)
        cms_pages2 = Cms::Page.where(site_id: site_old.id)
        cms_page2_skip = ["cms/page", "ads/banner", "facility/image", "key_visual/image"]
        cms_pages2.each do |cms_page2|
          if cms_page2_skip.include?(cms_page2.route)
              next
          end

          new_cms_page2_no_attr = {}
          new_model_attr_flag = 0
          new_model_attr = cms_page2.attributes.to_hash
          new_model_attr.delete("_id") if new_model_attr["_id"]
          new_model_attr.keys.each do |key|
            if !Cms::Page.fields.keys.include?(key)
              new_model_attr_flag = 1
              new_cms_page2_no_attr.store(key, cms_page2[key])
              new_model_attr.delete("#{key}")
            end
          end
          new_cms_page2 = Cms::Page.new(new_model_attr)
          new_cms_page2.site_id = site.id

          if new_model_attr_flag == 1
            new_cms_page2_no_attr.each do |noattr, val|
              new_cms_page2[noattr] = val
            end
          end

          files_param = _clone_files(cms_page2.file_ids, cms_page2.html)
          new_cms_page2["file_ids"] = files_param["file_ids"]
          new_cms_page2["html"] = files_param["html"]

          if cms_page2.layout_id && @layout_records_map[cms_page2.layout_id]
            new_cms_page2.layout_id = @layout_records_map[cms_page2.layout_id]
          end

          if cms_page2.route == "facility/page"
            new_cms_page2.category_ids = _pase_checkboxes_for_dupcms(node_pg_cats, "merge", cms_page2.category_ids)
          end

          new_cms_page2.save!
        end

    end

# ファイルを複製しファイルidを返す(単体)
    def _clone_file(old_file_id)
      old_file = SS::File.find(old_file_id)
      attributes = Hash[old_file.attributes]
      attributes.select!{ |k| old_file.fields.keys.include?(k) }

      file = SS::File.new(attributes)
      file.id = nil
      file.in_file = old_file.uploaded_file
      file.user_id = @cur_user.id if @cur_user

      file.save validate: false
      return file.id.mongoize
    end

# ファイルを複製しファイルidなどを返す(複数)
    def _clone_files(old_file_ids, html)
      return_param = {}
      return_param["file_ids"] = []
      return_param["html"] = html
      return return_param if old_file_ids.empty?

      old_file_ids.each do |old_file_id|
        old_file = SS::File.find(old_file_id)
        attributes = Hash[old_file.attributes]
        attributes.select!{ |k| old_file.fields.keys.include?(k) }

        file = SS::File.new(attributes)
        file.id = nil
        file.in_file = old_file.uploaded_file
        file.user_id = @cur_user.id if @cur_user

        file.save validate: false
        return_param["file_ids"].push(file.id.mongoize)

# NOTE:trだと複数ファイルコピー時にURL置換の挙動がおかしい（本来ファイルAを指すパスをファイルBのパスで書き換えている）
        return_param["html"].gsub!("=\"#{old_file.url}\"", "=\"#{file.url}\"")
      end
      return return_param
    end

    def _copy_checkboxes_for_dupcms(base_site, new_site, routes)
      if !base_site.kind_of?(Cms::Site) || !new_site.kind_of?(Cms::Site)
        logger.fatal 'Expected 2 arguments. - [0] => Cms::Site, [1] => Cms::Site'
        return false
      end

      node_cats = {}
      node_cats.store("merge", {})
      routes.each do |node_cat_route|
        node_cats.store(node_cat_route, {})
        Cms::Node.where(:site_id => base_site.id).where(route: node_cat_route).each do |base_cmsnode|

          old_cmsnode_id = base_cmsnode.id
          new_cmsnode_no_attr = {}
          new_model_attr_flag = 0
          new_model_attr = base_cmsnode.attributes.to_hash
          new_model_attr.delete("_id") if new_model_attr["_id"]
          new_model_attr.keys.each do |key|
            if !Cms::Node.fields.keys.include?(key)
              new_model_attr_flag = 1
              new_cmsnode_no_attr.store(key, base_cmsnode[key])
              new_model_attr.delete("#{key}")
            end
          end
          new_cmsnode = Cms::Node.new(new_model_attr)
          new_cmsnode.site_id = new_site.id

          if new_model_attr_flag == 1
            new_cmsnode_no_attr.each do |noattr, val|
                new_cmsnode[noattr] = val
            end
          end

          new_cmsnode.save validate: false
          node_cats[node_cat_route].store(old_cmsnode_id, new_cmsnode.id.mongoize)
          node_cats["merge"].store(old_cmsnode_id, new_cmsnode.id.mongoize)
        end
      end
      return node_cats
    end

    def _def_fac_checkboxes_for_dupcms(base_site, new_site, node_fac_cats)
      if !base_site.kind_of?(Cms::Site) || !new_site.kind_of?(Cms::Site)
        logger.fatal 'Expected 2 arguments. - [0] => Cms::Site, [1] => Cms::Site'
        return false
      end
      node_fac_new_cats = {}
      node_fac_cats.each do |key, val|
        node_fac_new_cats.store(key, [])
        val.each do |old_cat, new_cat|
          node_fac_new_cats[key].push(new_cat)
        end
      end
      @@node_copied_fac_cat_routes.each do |node_copied_cat_route|
        Cms::Node.where(:site_id => base_site.id).where(route: node_copied_cat_route).each do |base_cmsnode|
          old_cmsnode_id = base_cmsnode.id
          new_cmsnode_no_attr = {}
          new_model_attr_flag = 0
          new_model_attr = base_cmsnode.attributes.to_hash
          new_model_attr.delete("_id") if new_model_attr["_id"]
          new_model_attr.keys.each do |key|
            if !Cms::Node.fields.keys.include?(key)
              new_model_attr_flag = 1
              new_cmsnode_no_attr.store(key, base_cmsnode[key])
              new_model_attr.delete("#{key}")
            end
          end
          new_cmsnode = Cms::Node.new(new_model_attr)
          new_cmsnode.site_id = new_site.id

          if new_model_attr_flag == 1
            new_cmsnode_no_attr.each do |noattr, val|
                new_cmsnode[noattr] = val
            end
          end

          new_cmsnode["st_category_ids"] = node_fac_new_cats["facility/category"]
          new_cmsnode["st_service_ids"] = node_fac_new_cats["facility/service"]
          new_cmsnode["st_location_ids"] = node_fac_new_cats["facility/location"]

          new_cmsnode.save validate: false
        end
      end
    end

    def _pase_checkboxes_for_dupcms(ary, key, old_ids)
      chk_param = []
      old_ids.each do |old_id|
        chk_param.push(ary[key][old_id])
      end
      return chk_param
    end

  public
    def index
      @copy  = Sys::Copy.new
      @items = []
      render :action => 'index'
    end

    def confirm
      @run_flag = 1
      @host_flag = 1
      @domain_flag = 1
      @er_copy_site_mes = ''
      @er_name_mes = ''
      @er_host_mes = ''
      @er_domains_mes = ''

      if params["@copy"]["copy_site"].present?
        @site = Cms::Site.find(params["@copy"]["copy_site"])
        if @site.name.blank?
          @run_flag = 0
          @er_copy_site_mes = "存在しないサイトです。選択し直してください。"
        end
      else
        @run_flag = 0
        @er_copy_site_mes = "「複製するサイト」を選択してください。"
      end

      if params["@copy"]["name"].blank?
        @run_flag = 0
        @er_name_mes = "「サイト名」を入力してください。"
      end

      if params["@copy"]["host"].blank?
        @run_flag = 0
        @host_flag = 0
        @er_host_mes = "「ホスト名」を入力してください。"
      elsif Cms::Site.where(host: params["@copy"]["host"]).length > 0
        @run_flag = 0
        @host_flag = 0
        @er_host_mes = "入力したホスト名は既に使用しています。別のホスト名を入力してください。"
      elsif params["@copy"]["host"].length < 3
        @run_flag = 0
        @host_flag = 0
        @er_host_mes = "ホスト名は3文字以上で入力してください。"
      end

      if params["@copy"]["domains"].blank?
        @run_flag = 0
        @domain_flag = 0
        @er_domains_mes = "「ドメイン」を入力してください。"
      elsif Cms::Site.where(domains: params["@copy"]["domains"]).length > 0
        @run_flag = 0
        @domain_flag = 0
        @er_domains_mes = "入力したドメインは既に使用しています。別のドメインを入力してください。"
      end

    end

    def run
      Thread.start do
        site_old = Cms::Site.find(params["@copy_run"]["copy_site"])

#サイト生成：OK
        site = Cms::Site.create({
          group_ids:  site_old.group_ids,
          name:       params["@copy_run"]["name"],
          host:       params["@copy_run"]["host"],
          domains:    params["@copy_run"]["domains"]
        })

#権限複製：OK
        cms_roles = Cms::Role.where(site_id: site_old.id)
        new_cms_roles_id = {}
        cms_roles.each do |cms_role|
          new_cms_role = Cms::Role.new
          new_cms_role = cms_role.dup
          new_cms_role.site_id = site.id
          new_cms_role.save
          new_cms_roles_id.store(cms_role.id, new_cms_role.id)
        end

#ユーザへ新規権限付与：OK
        new_cms_roles_id.each do |old_role_id, new_role_id|
          cms_users = Cms::User.where(cms_role_ids: old_role_id)
          cms_users.each do |cms_user|
            cms_user.cms_role_ids = cms_user.cms_role_ids.push(new_role_id)
            cms_user.save
          end
        end

#必須コピー：フォルダー、固定ページ、レイアウト、パーツ
#レイアウト:OK
# NOTE: 20160301 - Cms::Node は "layout_id" を持つため "レイアウト" よりも後に処理を行うべきなので処理の順序を変更
        # 新旧レイアウトレコードIDのKeyVal
        # ex) {<BaseLayoutID>: <DupLayoutID>[, ...]}
        @layout_records_map = {}
        Cms::Layout.where(site_id: site_old.id).each do |cms_layout|
              new_cms_layout = Cms::Layout.new
              new_cms_layout = cms_layout.dup
              new_cms_layout.site_id = site.id
              if new_cms_layout.save
                @layout_records_map[cms_layout.id] = new_cms_layout.id
              end
        end

        #チェックボックス（「施設の種類」「施設の用途」「施設地域」）
        node_fac_cats = _copy_checkboxes_for_dupcms(site_old, site, @@node_fac_cat_routes)
        _def_fac_checkboxes_for_dupcms(site_old, site, node_fac_cats)

        #チェックボックス（カテゴリー）
        node_pg_cats = _copy_checkboxes_for_dupcms(site_old, site, @@node_pg_cat_routes)

        #フォルダ (uploader/file 配下で管理?するファイル含む)
        _copy_nodes_for_dupcms(site_old, site, node_fac_cats)

#固定ページ:OK
        cms_pages = Cms::Page.where(site_id: site_old.id, route: "cms/page")
        cms_pages.each do |cms_page|
              new_cms_page = Cms::Page.new
              new_cms_page = cms_page.dup
              new_cms_page.site_id = site.id
              new_cms_page.save
        end

#パーツ:OK
# NOTE:cms_part.dup だと失敗する
        cms_parts = Cms::Part.where(site_id: site_old.id)
        cms_parts.each do |cms_part|
              new_cms_part_no_attr = {}
              new_model_attr_flag = 0
              new_model_attr = cms_part.attributes.to_hash
              new_model_attr.delete("_id") if new_model_attr["_id"]
              new_model_attr.keys.each do |key|
                if !Cms::Part.fields.keys.include?(key)
                  new_model_attr_flag = 1
                  new_cms_part_no_attr.store(key, cms_part[key])
                  new_model_attr.delete("#{key}")
                end
              end
              new_cms_part = Cms::Part.new(new_model_attr)
              new_cms_part.site_id = site.id

              if new_model_attr_flag == 1
                new_cms_part_no_attr.each do |noattr, val|
                  new_cms_part[noattr] = val
                end
              end
              new_cms_part.save
        end

#選択コピー：記事・その他ページ、共有ファイル、テンプレート、かな辞書
#記事・その他ページ
        if params["@copy_run"]["article"] == "1"
            _create_dup_banner_for_dup_site(site_old, site)      #広告バナー
            _create_dup_facility_for_dup_site(site_old, site)    #施設写真 #TODO:コピーしたレイアウトIDを適用
            _create_dup_key_visuals_for_dup_site(site_old, site) #キービジュアル
            _create_dup_cms_page2_for_dup_site(site_old, site, node_pg_cats) #その他
        end

#共有ファイル:OK
        # 元サイトから共有ファイルを全て複製サイトへ複製
        if params["@copy_run"]["files"] == "1"
          _create_dupfiles_for_dupsite(site_old, site)
        end

#テンプレート:OK
        if params["@copy_run"]["editor_templates"] == "1"
            cms_templates = Cms::EditorTemplate.where(site_id: site_old.id)
            cms_templates.each do |cms_template|
              new_cms_template = Cms::EditorTemplate.new
              new_cms_template = cms_template.dup
              new_cms_template.site_id = site.id
              new_cms_template.save
            end
        end

#かな辞書:OK
        if params["@copy_run"]["dictionaries"] == "1"
            kana_dictionaries = Kana::Dictionary.where(site_id: site_old.id)
            kana_dictionaries.each do |kana_dictionary|
              new_kana_dictionary = Kana::Dictionary.new
              new_kana_dictionary = kana_dictionary.dup
              new_kana_dictionary.site_id = site.id
              new_kana_dictionary.save
            end
        end

      end
    end
end
