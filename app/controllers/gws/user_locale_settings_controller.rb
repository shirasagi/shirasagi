class Gws::UserLocaleSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter

  private

  def permit_fields
    [ :lang, :timezone ]
  end
end
