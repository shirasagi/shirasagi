class SS::Migration20190306000000
  include SS::Migration::Base

  depends_on "20190305000000"

  def change
    [ Gws::Portal::UserPortlet, Gws::Portal::GroupPortlet ].each do |model|
      all_ids = model.where(portlet_model: "ad").pluck(:id).sort
      all_ids.each_slice(20) do |ids|
        model.where(portlet_model: "ad").in(id: ids).to_a.each do |portlet|
          update_ad_portlet(portlet)
        end
      end
    end
  end

  private

  def update_ad_portlet(portlet)
    attrs = {}
    if portlet["time"].present?
      attrs[:ad_pause] = portlet["time"] * 1_000
    end
    if portlet["file_ids"].present?
      attrs[:ad_file_ids] = portlet["file_ids"]
    end

    if attrs.present?
      SS::File.in(id: attrs[:ad_file_ids]).each do |file|
        file.owner_item = portlet
        file.save!
      end

      portlet.set(attrs)
      portlet.unset("time", "file_ids")
    end
  end
end
