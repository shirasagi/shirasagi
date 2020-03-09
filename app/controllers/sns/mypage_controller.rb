class Sns::MypageController < ApplicationController
  include Sns::BaseFilter

  before_action :notices, only: [:index]

  private

  def cms_sites
    SS::Site.all.select do |site|
      @cur_user.groups.active.in(name: site.groups.active.pluck(:name).map{ |name| /^#{::Regexp.escape(name)}(\/|$)/ } ).present?
    end
  end

  def gws_sites
    @cur_user.root_groups.select { |group| group.gws_use? }
  end

  def notices
    @notices = Sys::Notice.and_public.sys_admin_notice.page(1).per(5)
  end

  public

  def index
    @cms_sites = cms_sites
    @gws_sites = gws_sites
  end

  def cms
    @sites = cms_sites

    if @sites.size == 1
      redirect_to cms_contents_path(@sites.first)
    else
      redirect_to sns_mypage_path
    end
  end

  def gws
    @sites = gws_sites

    if @sites.size == 1
      redirect_to gws_portal_path(@sites.first)
    else
      redirect_to sns_mypage_path
    end
  end
end
