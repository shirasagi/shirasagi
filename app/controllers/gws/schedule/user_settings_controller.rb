class Gws::Schedule::UserSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter
end
