# coding: utf-8
module Opendata::Reference
  module Member
    extend ActiveSupport::Concern

    included do
      scope :member, ->(member) { where(member_id: member.id) }

      belongs_to :member, class_name: "Opendata::Member"
    end
  end
end
