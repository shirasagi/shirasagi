class SS::Migration20250417000001
  include SS::Migration::Base

  depends_on "20250417000000"

  def change
    # put your migration code here
    each_portlet do |portlet|
      changed = false
      if portlet.attributes["time"].present?
        portlet.ad_pause = portlet.attributes["time"] * 1_000
        changed = true
      end

      file_ids = portlet["file_ids"]
      if file_ids.present?
        SS::File.unscoped.in(id: file_ids).to_a.each do |file|
          url = file.attributes["link_url"]
          portlet.ad_links.build(url: url, file_id: file.id, target: "_blank", state: "show")
        end
        changed = true
      end

      ad_file_ids = portlet["ad_file_ids"]
      if ad_file_ids.present?
        SS::File.unscoped.in(id: ad_file_ids).to_a.each do |ad_file|
          url = ad_file.attributes["link_url"]
          portlet.ad_links.build(url: url, file_id: ad_file.id, target: "_blank", state: "show")
        end
        changed = true
      end

      next unless changed

      result = portlet.without_record_timestamps { portlet.save }
      unless result
        warn "failed to migrate ad files to ad links\n#{portlet.errors.full_messages.join("\n")}"
      end
    ensure
      portlet.unset("time", "file_ids", "ad_file_ids")
    end
  end

  private

  def each_portlet
    [ Gws::Portal::UserPortlet, Gws::Portal::GroupPortlet ].each do |model|
      all_ids = model.where(portlet_model: "ad").pluck(:id).sort
      all_ids.each_slice(20) do |ids|
        model.where(portlet_model: "ad").in(id: ids).to_a.each do |portlet|
          yield portlet
        end
      end
    end
  end
end
