module Category::Addon
  module Split
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      attr_accessor :in_partial_name, :in_partial_basename
      permit_params :in_partial_name, :in_partial_basename
    end

    def split
      partial = self.class.new
      partial.attributes = self.attributes

      partial.id = nil
      partial.cur_user = @cur_user
      partial.cur_site = @cur_site

      partial.name = in_partial_name
      partial.basename = in_partial_basename

      path = File.dirname(filename)
      partial.cur_node = Cms::Node.site(@cur_site).in_path(path).sort(depth: -1).first

      validate_split(partial)
      if errors.empty?
        partial.save
        integrate_embeds_ids(self, partial, Cms::Node)
        integrate_embeds_ids(self, partial, Cms::Page)
        true
      else
        false
      end
    end

    def validate_split(partial)
      # validate partial save
      if !partial.valid?
        partial.errors.each do |n, e|
          self.errors.add n, e
        end
      end
    end

    def integrate_embeds_ids(embedded, insert, content_model)
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
          next unless ids.include?(embedded.id)
          item.add_to_set(k => insert.id)
        end
      end
    end
  end
end
