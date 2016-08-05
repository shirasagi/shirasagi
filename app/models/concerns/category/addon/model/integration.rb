module Category::Addon::Model
  module Integration
    extend ActiveSupport::Concern
    extend SS::Translation

    def integrate_embeds_ids(content, insert, content_model)
      item_ids = content_model.site(@cur_site).pluck(:id)
      item_ids.each do |item_id|
        item = content_model.site(@cur_site).find(item_id).becomes_with_route rescue nil
        next false unless item

        embeds_fields = item.fields.select do |n, v|
          next false unless n =~ /_ids$/
          next false unless v.type == SS::Extensions::ObjectIds

          begin
            elem_class = v.metadata[:elem_class]
            elem_class.constantize.include?(Cms::Model::Node)
          rescue
            false
          end
        end

        embeds_fields.keys.each do |k|
          ids = item.send(k)
          next unless ids.include?(content.id)
          item.add_to_set(k => insert.id)
        end
      end
    end
  end
end
