# coding: utf-8
module Opendata::MypageFilter
  extend ActiveSupport::Concern

  included do
    before_action :logged_in?
  end

  private
    def remote_addr
      request.env["HTTP_X_REAL_IP"] || request.remote_addr
    end

    def logged_in?(opts = {})
      return @cur_member if @cur_member

      if session[:member]
        u = SS::Crypt.decrypt(session[:member]).to_s.split(",", 3)
        return unset_user redirect: true if u[1] != remote_addr
        return unset_user redirect: true if u[2] != request.user_agent
        @cur_member = Cms::Member.find u[0].to_i rescue nil
      end

      return @cur_member if @cur_member
      unset_member redirect: true if opts[:redirect] != false
    end

    def set_member(member, opt = {})
      if opt[:session]
        session[:member] = SS::Crypt.encrypt("#{member._id},#{remote_addr},#{request.user_agent}")
      end
      controller.redirect_to "/mypage/" if opt[:redirect]
      @cur_member = member
    end

    def unset_member(opt = {})
      session[:member] = nil
      controller.redirect_to "/mypage/login" if opt[:redirect]
      @cur_member = nil
    end
end
