module Opendata::MemberFilter
  extend ActiveSupport::Concern

  included do
    before_action :convert_member
  end

  private
    def convert_member
      @cur_member = Opendata::Member.find(@cur_member.id) if @cur_member
    end
end
