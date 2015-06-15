module Opendata::Addon::Appfile
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_many :appfiles, class_name: "Opendata::Appfile"
    before_destroy :destroy_appfiles
  end

  def destroy_appfiles
    appfiles.destroy
  end
end
