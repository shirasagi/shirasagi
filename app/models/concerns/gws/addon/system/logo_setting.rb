module Gws::Addon::System::LogoSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include SS::Model::LogoSetting

  set_addon_type :organization
end
