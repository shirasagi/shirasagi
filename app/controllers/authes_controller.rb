# coding: utf-8
class AuthesController < ApplicationController

  public
    def callback
      site = session[:auth_site]
      session[:auth_site] = nil
      auth = request.env["omniauth.auth"]
      member = Cms::Member.where(oauth_type: auth.provider, oauth_id: auth.uid).first
      if member
        #外部認証済みの場合、ログイン
        session[:member] = SS::Crypt.encrypt("#{member.id},#{remote_addr},#{request.user_agent}")
        redirect_to "/mypage/"
      else
        #外部認証していない場合、ログイン情報を保存してから、ログインさせる
        Cms::Member.create_auth_member(auth, site)
        member = Cms::Member.where(oauth_type: auth.provider, oauth_id: auth.uid).first
        session[:member] = SS::Crypt.encrypt("#{member.id},#{remote_addr},#{request.user_agent}")
        redirect_to "/mypage/"
      end
    end

    def fail
      session[:auth_site] = nil
      session[:member] = nil
      redirect_to "/mypage/login"
    end
end
