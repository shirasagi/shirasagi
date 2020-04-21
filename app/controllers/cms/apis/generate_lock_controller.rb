class Cms::Apis::GenerateLockController < ApplicationController
  include Cms::ApiFilter

  before_action :check_permission

  private

  def check_permission
    raise "403" unless Cms::GenerateLock.allowed?(:edit, @cur_user, site: @cur_site)
  end

  public

  def lock
    @cur_site.generate_lock(params['generate_lock'])
  end

  def unlock
    @cur_site.generate_unlock
    render action: :lock
  end
end
