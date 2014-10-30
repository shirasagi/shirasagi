module History::Agents::Addons::Backup
  class EditController < ApplicationController
    include SS::AddonFilter::Edit

    def show
      return render(text: "") if @item.backups.size == 0
      super
    end
  end
end
