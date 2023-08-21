module SS::Reference
  module Group
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_group

    included do
      belongs_to :group, class_name: "SS::Group"

      validates :group_id, presence: true
      before_validation :set_group_id, if: ->{ @cur_group }

      scope :group, ->(group) { where( group_id: group.id ) }
    end

    private

    def set_group_id
      self.group_id ||= @cur_group.id
    end
  end
end
