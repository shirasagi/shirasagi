module Opendata::Addon::Appfile
  extend SS::Addon
  extend ActiveSupport::Concern

  set_order 200

  included do
    embeds_many :appfiles, class_name: "Opendata::App::Appfile"
    before_destroy :destroy_appfiles
  end

  def destroy_appfiles
    appfiles.destroy
  end
end
