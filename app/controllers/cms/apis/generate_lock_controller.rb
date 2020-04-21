class Cms::Apis::GenerateLockController < ApplicationController
  include Cms::ApiFilter

  before_action :check_permission

  private

  def check_permission
    raise "403" unless Cms::GenerateLock.allowed?(:edit, @cur_user, site: @cur_site)
  end

  public

  def lock
    @cur_site.generate_lock(params['generate_lock'], user: @cur_user)
    if @cur_site.generate_lock_until.present?
      @generate_lock_until = I18n.l(@cur_site.generate_lock_until, format: :long)
      @generate_lock_until += "<span>("
      @generate_lock_until += ERB::Util.html_escape(@cur_user.name)
      @generate_lock_until += ")</span>"
      @notice = I18n.t('cms.notices.generate_locked')
    else
      unlock
    end
  end

  def unlock
    @cur_site.generate_unlock(user: @cur_user)
    @generate_lock_until = @cur_site.t(:generate_unlocked)
    @notice = I18n.t('cms.notices.generate_unlocked')
    render action: :lock
  end
end
