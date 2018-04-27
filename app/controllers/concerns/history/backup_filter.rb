module History::BackupFilter
  extend ActiveSupport::Concern

  def show
    #
  end

  def restore
    #
  end

  def update
    if @item.restore
      redirect_to({ action: :show }, { notice: I18n.t("history.notice.restored") })
    else
      render action: :restore
    end
  end

  def change
    #
  end
end
