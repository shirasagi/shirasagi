class Sns::Frames::UserNavigationsController < ApplicationController
  include Sns::BaseFilter

  layout "ss/item_frame"

  before_action :set_frame_id

  attr_reader :cur_user

  helper_method :ss_mode, :cur_user, :cur_group, :cms_site, :gws_site

  private

  def set_item
  end

  def set_frame_id
    @frame_id = "user-navigation-frame"
  end

  def ss_mode
    @ss_mode ||= params[:ss_mode].to_s.to_sym
  end

  def logged_in?
    save_user_class = self.user_class
    case ss_mode
    when :cms
      self.user_class = Cms::User
    when :gws
      self.user_class = Gws::User
    end

    super
  ensure
    if @cur_user
      case ss_mode
      when :cms
        @cur_user.cur_site = cms_site
      when :gws
        @cur_user.cur_site = gws_site
      end
    end

    self.user_class = save_user_class
  end

  def cms_site
    return @cms_site if instance_variable_defined?(:@cms_site)

    if ss_mode != :cms || !params.key?(:site)
      @cms_site = nil
      return @cms_site
    end

    @cms_site = Cms::Site.find(params[:site].to_s)
  end

  def gws_site
    return @gws_site if instance_variable_defined?(:@gws_site)

    if ss_mode != :gws || !params.key?(:site)
      @gws_site = nil
      return @gws_site
    end

    @gws_site = Gws::Group.find(params[:site].to_s)
  end

  def cur_group
    return @cur_group if instance_variable_defined?(:@cur_group)

    if ss_mode != :gws
      @cur_group = nil
      return @cur_group
    end

    @cur_group = @cur_user.gws_default_group
  end

  def logout_path
    if ss_mode == :gws
      return gws_logout_path(site: gws_site)
    end
    super
  end

  public

  def show
    render
  end
end
