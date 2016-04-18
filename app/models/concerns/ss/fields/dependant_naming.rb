module SS::Fields::DependantNaming
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:name_field, instance_accessor: false) { "name" }
    attr_accessor :skip_rename_children
    after_save :rename_children, if: ->{ @db_changes && !skip_rename_children }
  end

  def trailing_name
    send(self.class.name_field).split("/").pop
  end

  def depth
    name.scan("/").size + 1
  end

  private
    def dependant_scope
      self.class.all
    end

    def rename_children
      changes = @db_changes[self.class.name_field]
      return unless changes

      src = changes[0]
      return unless src

      dst = changes[1]
      return unless dst

      dependant_scope.ne(_id: _id).where(self.class.name_field => /^#{Regexp.escape(src)}\//).each do |item|
        val = item[self.class.name_field]
        val = val.sub(/^#{Regexp.escape(src)}\//, "#{dst}/")
        item[self.class.name_field] = val
        item.skip_rename_children = true
        item.save(validate: false)
      end
    end
end
