require 'spec_helper'

RSpec.describe Map::MapHelper, type: :helper do
  subject(:markers) do
    [
      {
        name: "マーカー１",
        loc: [34.099866, 134.137917],
        text: "テキスト１"
      },
      {
        name: "マーカー２",
        loc: [34.099866, 133.137917],
        text: "テキスト２"
      },
      {
        name: "マーカー３",
        loc: [33.916014, 133.779145],
        text: "テキスト３"
      }
    ]
  end
  subject(:googlemaps_site) do
    create_once :cms_site, name: "A", host: "googlemaps", domains: "googlemaps.localhost.jp",
      map_api: "googlemaps", map_api_key: "AAA"
  end
  subject(:openlayers_site) do
    create_once :cms_site, name: "B", host: "openlayers", domains: "openlayers.localhost.jp",
      map_api: "openlayers"
  end

  subject(:map) { helper.render_map "#map-canvas", markers: markers }
  subject(:map_form) { helper.render_map_form "#map-canvas", markers: markers }
  subject(:facility_search_map) { helper.render_facility_search_map "#map-canvas", markers: markers }
  subject(:member_photo_form_map) { helper.render_member_photo_form_map "#map-canvas", markers: markers }

  subject(:map_g) { helper.render_map "#map-canvas", markers: markers, site: googlemaps_site }
  subject(:map_form_g) { helper.render_map_form "#map-canvas", markers: markers, site: googlemaps_site }
  subject(:facility_search_map_g) { helper.render_facility_search_map "#map-canvas", markers: markers, site: googlemaps_site }
  subject(:member_photo_form_map_g) { helper.render_member_photo_form_map "#map-canvas", markers: markers, site: googlemaps_site }

  subject(:map_o) { helper.render_map "#map-canvas", markers: markers, site: openlayers_site }
  subject(:map_form_o) { helper.render_map_form "#map-canvas", markers: markers, site: openlayers_site }
  subject(:facility_search_map_o) { helper.render_facility_search_map "#map-canvas", markers: markers, site: openlayers_site }
  subject(:member_photo_form_map_o) { helper.render_member_photo_form_map "#map-canvas", markers: markers, site: openlayers_site }

  describe 'map_helpers' do
    before do
      allow(controller).to receive(:javascript).and_return(true)
      allow(controller).to receive(:stylesheet).and_return(true)
    end

    context 'with openlayers api by yml setting' do
      before { SS.config.replace_value_at(:map, :api, "openlayers") }

      it 'render_map' do
        expect(map).to include('Openlayers_Map(canvas, opts)')
      end

      it 'render_map_form' do
        expect(map_form).to include('Openlayers_Map_Form(canvas, opts)')
      end

      it 'render_facility_search_map' do
        expect(facility_search_map).to include('Openlayers_Facility_Search.render("#map-canvas", opts)')
      end

      it 'render_member_photo_form_map' do
        expect(member_photo_form_map).to include('Openlayers_Member_Photo_Form(canvas, opts)')
      end
    end

    context 'with openlayers api by site setting' do
      before { SS.config.replace_value_at(:map, :api, "googlemaps") }

      it 'render_map' do
        expect(map_o).to include('Openlayers_Map(canvas, opts)')
      end

      it 'render_map_form' do
        expect(map_form_o).to include('Openlayers_Map_Form(canvas, opts)')
      end

      it 'render_facility_search_map' do
        expect(facility_search_map_o).to include('Openlayers_Facility_Search.render("#map-canvas", opts)')
      end

      it 'render_member_photo_form_map' do
        expect(member_photo_form_map_o).to include('Openlayers_Member_Photo_Form(canvas, opts)')
      end
    end

    context 'with googlemaps api by yml setting' do
      before { SS.config.replace_value_at(:map, :api, "googlemaps") }

      it 'render_map' do
        expect(map).to include('Map.load("#map-canvas")')
      end

      it 'render_map_form' do
        expect(map_form).to include('Map.setForm(Map_Form)')
      end

      it 'render_facility_search_map' do
        expect(facility_search_map).to include('Facility_Search.render("#map-canvas", opts)')
      end

      it 'render_member_photo_form_map' do
        expect(member_photo_form_map).to include('Map.setForm(Member_Photo_Form)')
      end
    end

    context 'with googlemaps api by site setting' do
      before { SS.config.replace_value_at(:map, :api, "openlayers") }

      it 'render_map' do
        expect(map_g).to include('Map.load("#map-canvas")')
      end

      it 'render_map_form' do
        expect(map_form_g).to include('Map.setForm(Map_Form)')
      end

      it 'render_facility_search_map' do
        expect(facility_search_map_g).to include('Facility_Search.render("#map-canvas", opts)')
      end

      it 'render_member_photo_form_map' do
        expect(member_photo_form_map_g).to include('Map.setForm(Member_Photo_Form)')
      end
    end
  end
end
