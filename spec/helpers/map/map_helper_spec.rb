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
  subject(:r_map) { helper.render_map "#map-canvas", markers: markers }
  subject(:r_map_form) { helper.render_map_form "#map-canvas", markers: markers }
  subject(:r_facility_search_map) { helper.render_facility_search_map "#map-canvas", markers: markers }
  subject(:r_member_photo_form_map) { helper.render_member_photo_form_map "#map-canvas", markers: markers }

  describe 'map_helpers' do
    before do
      allow(controller).to receive(:javascript).and_return(true)
      allow(controller).to receive(:stylesheet).and_return(true)
    end

    context 'with openlayers api' do
      before { SS.config.replace_value_at(:map, :api, "openlayers") }

      it 'render_map' do
        expect(r_map).to include('Openlayers_Map(canvas, opts)')
      end

      it 'render_map_form' do
        expect(r_map_form).to include('Openlayers_Map_Form(canvas, opts)')
      end

      it 'render_facility_search_map' do
        expect(r_facility_search_map).to include('Openlayers_Facility_Search.render("#map-canvas", opts)')
      end

      it 'render_member_photo_form_map' do
        expect(r_member_photo_form_map).to include('Openlayers_Member_Photo_Form(canvas, opts)')
      end
    end

    context 'with googlemaps api' do
      before { SS.config.replace_value_at(:map, :api, "googlemaps") }

      it 'render_map' do
        expect(r_map).to include('Map.load("#map-canvas")')
      end

      it 'render_map_form' do
        expect(r_map_form).to include('Map.setForm(Map_Form)')
      end

      it 'render_facility_search_map' do
        expect(r_facility_search_map).to include('Facility_Search.render("#map-canvas", opts)')
      end

      it 'render_member_photo_form_map' do
        expect(r_member_photo_form_map).to include('Map.setForm(Member_Photo_Form)')
      end
    end
  end
end
