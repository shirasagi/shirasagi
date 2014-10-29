module History::BackupFilter
  extend ActiveSupport::Concern

  public
    def show
      #
    end

    def restore
      #
    end

    def update
      @item.restore
      redirect_to({ action: :show }, { notice: I18n.t("history.notice.restored") })
    end
end
