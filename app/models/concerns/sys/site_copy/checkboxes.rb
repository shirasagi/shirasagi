module Sys::SiteCopy::Checkboxes
  extend ActiveSupport::Concern
  private
    @@node_fac_cat_routes = ["facility/location", "facility/category", "facility/service"]
    @@node_copied_fac_cat_routes = ["facility/search", "facility/node"]
    @@node_pg_cat_routes = ["category/node", "category/page"]

    def copy_checkboxes_for_dupcms(routes)
      if !@site_old.kind_of?(Cms::Site) || !@site.kind_of?(Cms::Site)
        logger.fatal 'Expected 2 arguments. - [0] => Cms::Site, [1] => Cms::Site'
        return false
      end

      node_cats = {}
      node_cats.store("merge", {})
      routes.each do |node_cat_route|
        node_cats.store(node_cat_route, {})
        Cms::Node.where(:site_id => @site_old.id).where(route: node_cat_route).each do |base_cmsnode|

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
          new_cmsnode.site_id = @site.id

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

    def def_fac_checkboxes_for_dupcms(node_fac_cats)
      if !@site_old.kind_of?(Cms::Site) || !@site.kind_of?(Cms::Site)
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
        Cms::Node.where(:site_id => @site_old.id).where(route: node_copied_cat_route).each do |base_cmsnode|
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
          new_cmsnode.site_id = @site.id

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

    def pase_checkboxes_for_dupcms(ary, key, old_ids)
      chk_param = []
      old_ids.each do |old_id|
        chk_param.push(ary[key][old_id])
      end
      return chk_param
    end

end