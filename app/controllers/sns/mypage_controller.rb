class Sns::MypageController < ApplicationController
  include Sns::BaseFilter

  before_action :notices, only: [:index]

  private

  def notices
    @notices = Sys::Notice.and_public.sys_admin_notice.reorder(notice_severity: 1, released: -1, id: -1).page(1).per(5)
  end

  public

  def index
    @cms_sites = SS.cms_sites(@cur_user)
    @gws_sites = SS.gws_sites(@cur_user)
  end

  def cms
    @sites = SS.cms_sites(@cur_user)

    if @sites.size == 1
      redirect_to cms_contents_path(@sites.first)
    else
      redirect_to sns_mypage_path
    end
  end

  def gws
    @sites = SS.gws_sites(@cur_user)

    if @sites.size == 1
      redirect_to gws_portal_path(@sites.first)
    else
      redirect_to sns_mypage_path
    end
  end
end
