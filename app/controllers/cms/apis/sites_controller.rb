class Cms::Apis::SitesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Site

  before_action :set_single

  private

  def set_single
    @single = params[:single].present?
    @multi = !@single
  end

  public

  def index
    @items = @model.all.allow(:read, @cur_user, site: @cur_site)
    @items = @items.search(params[:s])
    @items = @items.order_by(_id: -1)
    @items = @items.page(params[:page]).per(50)

    # see: app/controllers/sns/mypage_controller.rb
    @items = @items.to_a.select do |site|
      @cur_user.groups.active.in(name: site.groups.active.pluck(:name).map{ |name| /^#{::Regexp.escape(name)}(\/|$)/ } ).present?
    end
  end
end
