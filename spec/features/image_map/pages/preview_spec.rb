require 'spec_helper'

describe "image_map_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:part) { create :cms_part_free, html: '<meta name="foo" content="bar" />' }
  let(:layout_html) do
    html = []
    html << "<html><head>"
    html << "{{ part \"#{part.filename.sub(/\..*/, '')}\" }}"
    html << "</head><body><br><br><br><div id=\"main\" class=\"page\">"
    html << "{{ yield }}"
    html << "</div></body></html>"
    html.join("\n")
  end
  let(:layout) { create :cms_layout, html: layout_html }
  let!(:node) { create_once :image_map_node_page, filename: "image-map", name: "image-map" }

  let(:usemap) { "image-map-#{node.id}" }
  let(:coords1) { [0, 0, 100, 100] }
  let(:coords2) { [10, 10, 110, 110] }

  let!(:item1) { create(:image_map_page, cur_node: node, coords: coords1, order: 10) }
  let!(:item2) { create(:image_map_page, cur_node: node, coords: coords2, order: 20, state: "closed") }

  before { login_cms_user }

  describe "page preview" do
    before do
      visit item2.private_show_path
      within "#addon-workflow-agents-addons-branch" do
        wait_for_turbo_frame "#workflow-branch-frame"
        wait_for_event_fired "turbo:frame-load" do
          click_button I18n.t('workflow.create_branch')
        end
        expect(page).to have_css('.see.branch')
      end
    end

    context "item1" do
      it do
        visit cms_preview_path(site: site, path: item1.preview_path)

        expect(page).to have_css("img[usemap=\"\##{usemap}\"]")
        within "map[name=\"#{usemap}\"]" do
          expect(page).to have_css("area[href=\"\#area-content-1\"][coords=\"#{coords1.join(",")}\"]")
          expect(page).to have_no_css("area[href=\"\#area-content-2\"][coords=\"#{coords2.join(",")}\"]")
        end
      end
    end

    context "item2" do
      it do
        visit cms_preview_path(site: site, path: item2.preview_path)

        expect(page).to have_css("img[usemap=\"\##{usemap}\"]")
        within "map[name=\"#{usemap}\"]" do
          expect(page).to have_css("area[href=\"\#area-content-1\"][coords=\"#{coords1.join(",")}\"]")
          expect(page).to have_css("area[href=\"\#area-content-2\"][coords=\"#{coords2.join(",")}\"]")
        end
      end
    end
  end
end
