class SS::Migration20250602000000
  include SS::Migration::Base

  def change
    Cms::Site.each do |site|
      next if site[:show_google_maps_search] != "expired"
      site.set(show_google_maps_search_in_marker: "hide")
    end
  end
end
