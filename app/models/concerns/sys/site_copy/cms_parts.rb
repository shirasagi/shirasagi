module Sys::SiteCopy::CmsParts
  extend ActiveSupport::Concern

  private
    #パーツ:OK
    # NOTE:cms_part.dup だと失敗する
    def copy_cms_parts
      cms_parts = Cms::Part.where(site_id: @site_old.id)
      cms_parts.each do |cms_part|
        cms_part = cms_part.becomes_with_route
        new_cms_part = cms_part.class.new cms_part.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_cms_part.site_id = @site.id
        if cms_part.attributes["search_node_id"]
          source_search_node = Cms::Node.where(id: cms_part.attributes["search_node_id"]).one
          dest_search_node = Cms::Node.where(site_id: @site.id, filename: source_search_node.filename).one
          new_cms_part.search_node_id = dest_search_node.id
        end
        begin
          new_cms_part.save!
        rescue => exception
          Rails.logger.error(exception.message)
          throw exception
        end
      end
    end
end
