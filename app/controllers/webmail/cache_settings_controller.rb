class Webmail::CacheSettingsController < ApplicationController
  include Webmail::BaseFilter

  menu_view false

  private
    def set_crumbs
      @crumbs << [:"webmail.settings.cache" , { action: :show } ]
    end

  public
    def show
      # render
    end

    def update
      if params[:model] == 'mail'
        clear_cache_mail
      elsif params[:model] == 'mailbox'
        clear_cache_mailbox
      end
    end

    def clear_cache_mail
      Webmail::Mail.user(@cur_user).destroy_all
      render_destroy
    end

    def clear_cache_mailbox
      Webmail::Mailbox.user(@cur_user).destroy_all
      render_destroy
    end

    def render_destroy
      location = { action: :show }

      respond_to do |format|
        format.html { redirect_to location, notice: t('webmail.notice.deleted_cache') }
        format.json { head :no_content }
      end
    end
end
