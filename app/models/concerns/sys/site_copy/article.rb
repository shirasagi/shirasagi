module Sys::SiteCopy::Article
  extend ActiveSupport::Concern

  private
    #記事・その他ページ
    def copy_article(node_pg_cats, layout_records_map)
      @layout_records_map = layout_records_map
      create_dup_banner_for_dup_site                  #広告バナー
      create_dup_facility_for_dup_site                #施設写真 #TODO:コピーしたレイアウトIDを適用
      create_dup_key_visuals_for_dup_site             #キービジュアル
      create_dup_cms_page2_for_dup_site(node_pg_cats) #その他
    end

    #広告バナー
    def create_dup_banner_for_dup_site
      if !@site_old.kind_of?(Cms::Site) || !@site.kind_of?(Cms::Site)
        logger.fatal 'Expected 2 arguments. - [0] => Cms::Site, [1] => Cms::Site'
        return false
      end
      cms_ads = Ads::Banner.where(site_id: @site_old.id).where(route: "ads/banner").order('depth ASC')
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
        new_cms_ad.site_id = @site.id
        new_cms_ad.name = cms_ad.name
        new_cms_ad.filename = cms_ad.filename
        new_cms_ad.link_url = cms_ad.link_url
        new_cms_ad.file_id  = clone_file(cms_ad.file_id)
        if cms_ad.layout_id && @layout_records_map[cms_ad.layout_id]
          new_cms_ad.layout_id = @layout_records_map[cms_ad.layout_id]
        end

        new_cms_ad.save!
      end
    end

    #施設写真
    def create_dup_facility_for_dup_site
      cms_facilities = Facility::Image.where(site_id: @site_old.id).where(route: "facility/image")
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
        new_cms_facility.site_id = @site.id
        new_cms_facility.name = cms_facility.name
        new_cms_facility.filename = cms_facility.filename
        new_cms_facility.layout_id = cms_facility.layout_id #TODO:コピーしたレイアウトIDを適用
        new_cms_facility.image_id = clone_file(cms_facility.image_id)
        if cms_facility.layout_id && @layout_records_map[cms_facility.layout_id]
          new_cms_facility.layout_id = @layout_records_map[cms_facility.layout_id]
        end
        new_cms_facility.save!
      end
    end

    #キービジュアル
    def create_dup_key_visuals_for_dup_site
      cms_key_visuals = KeyVisual::Image.where(site_id: @site_old.id).where(route: "key_visual/image")
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
        new_cms_key_visual.site_id = @site.id

        if new_model_attr_flag == 1
          new_cms_key_visual_no_attr.each do |noattr, val|
            new_cms_key_visual[noattr] = val
          end
        end

        new_cms_key_visual.file_id = clone_file(cms_key_visual.file_id)
        if cms_key_visual.layout_id && @layout_records_map[cms_key_visual.layout_id]
          new_cms_key_visual.layout_id = @layout_records_map[cms_key_visual.layout_id]
        end

        new_cms_key_visual.save!
      end
    end

    #その他の記事・その他ページ
    def create_dup_cms_page2_for_dup_site(node_pg_cats)
      cms_pages2 = Cms::Page.where(site_id: @site_old.id)
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
        new_cms_page2.site_id = @site.id

        if new_model_attr_flag == 1
          new_cms_page2_no_attr.each do |noattr, val|
            new_cms_page2[noattr] = val
          end
        end

        files_param = clone_files(cms_page2.file_ids, cms_page2.html)
        new_cms_page2["file_ids"] = files_param["file_ids"]
        new_cms_page2["html"] = files_param["html"]

        if cms_page2.layout_id && @layout_records_map[cms_page2.layout_id]
          new_cms_page2.layout_id = @layout_records_map[cms_page2.layout_id]
        end

        if cms_page2.route == "facility/page"
          new_cms_page2.category_ids = Sys::SiteCopy::Checkboxes.pase_checkboxes_for_dupcms(node_pg_cats, "merge", cms_page2.category_ids)
        end

        new_cms_page2.save!
      end
    end

    # ファイルを複製しファイルidを返す(単体)
    def clone_file(old_file_id)
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
    def clone_files(old_file_ids, html)
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
end