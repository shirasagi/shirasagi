module SS::Fields::DependantNaming
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:name_field, instance_accessor: false) { "name" }
    after_save :rename_children, if: ->{ @db_changes }
  end

  def rename_children
    changes = @db_changes[self.class.name_field]
    return unless changes

    src = changes[0]
    return unless src

    dst = changes[1]
    return unless dst

    self.class.where(self.class.name_field => /^#{Regexp.escape(src)}\//).each do |item|
      val = item[self.class.name_field]
      val = val.sub(/^#{Regexp.escape(src)}\//, "#{dst}/")
      item[self.class.name_field] = val
      item.save(validate: false)
    end
  end
end
