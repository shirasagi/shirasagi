module Category::Addon
  module Split
    extend SS::Addon
    extend ActiveSupport::Concern
    include ::Category::Addon::Model::Integration

    included do
      attr_accessor :in_partial_name, :in_partial_basename
      permit_params :in_partial_name, :in_partial_basename
    end

    def category_split
      partial = self.class.new
      partial.attributes = self.attributes

      partial.id = nil
      partial.cur_user = @cur_user
      partial.cur_site = @cur_site

      partial.name = in_partial_name
      partial.basename = in_partial_basename

      path = File.dirname(filename)
      partial.cur_node = Cms::Node.site(@cur_site).in_path(path).sort(depth: -1).first

      validate_category_split(partial)
      if errors.empty?
        partial.save
        integrate_embeds_ids(self, partial, Cms::Node)
        integrate_embeds_ids(self, partial, Cms::Page)
        true
      else
        false
      end
    end

    def validate_category_split(partial)
      # validate partial save
      if !partial.valid?
        partial.errors.each do |n, e|
          self.errors.add n, e
        end
      end
    end
  end
end
