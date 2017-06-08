module Cms::Reference
  module Member
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_member

    included do
      belongs_to :member, class_name: "Cms::Member"
      before_validation :set_member_id, if: ->{ @cur_member }

      scope :member, ->(member) { where(member_id: member.id) }

      if respond_to?(:template_variable_handler)
        template_variable_handler :contributor, :template_variable_handler_contributor
      end
    end

    def contributor
      member ? member.name : user.name
    rescue
      nil
    end

    private

    def set_member_id
      self.member_id ||= @cur_member.id
    end

    def template_variable_handler_contributor(name, issuer)
      ERB::Util.html_escape contributor
    end
  end
end
