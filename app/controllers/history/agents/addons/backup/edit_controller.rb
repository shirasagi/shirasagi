module History::Agents::Addons::Backup
  class EditController < ApplicationController
    include SS::AddonFilter::Edit

    def show
      return render(text: "") if @item.backups.size == 0
      return render(text: "") unless @item.allowed?(:edit, @cur_user)
      super
    end
  end
end
