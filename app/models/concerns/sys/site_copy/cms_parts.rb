module Sys::SiteCopy::CmsParts
  extend ActiveSupport::Concern

  private
    #パーツ:OK
    # NOTE:cms_part.dup だと失敗する
    def copy_cms_parts
      cms_parts = Cms::Part.where(site_id: @site_old.id)
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
        new_cms_part.site_id = @site.id

        if new_model_attr_flag == 1
          new_cms_part_no_attr.each do |noattr, val|
            new_cms_part[noattr] = val
          end
        end
        new_cms_part.save
      end
    end
end