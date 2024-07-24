require 'spec_helper'

describe "lsorg_agents_nodes_node", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  let!(:g1) { cms_group }
  let!(:g1_1) { create :cms_group, name: "#{g1.name}/#{unique_id}" }
  let!(:g1_1_1) { create :cms_group, name: "#{g1_1.name}/#{unique_id}", overview: unique_id }
  let!(:g1_1_2) { create :cms_group, name: "#{g1_1.name}/#{unique_id}", overview: unique_id }
  let!(:g1_2) { create :cms_group, name: "#{g1.name}/#{unique_id}" }
  let!(:g1_2_1) { create :cms_group, name: "#{g1_2.name}/#{unique_id}", overview: unique_id }
  let!(:g1_2_2) { create :cms_group, name: "#{g1_2.name}/#{unique_id}", overview: unique_id }
  let!(:g1_3) { create :cms_group, name: "#{g1.name}/#{unique_id}" }
  let!(:g1_3_1) { create :cms_group, name: "#{g1_3.name}/#{unique_id}", overview: unique_id }
  let!(:g1_3_2) { create :cms_group, name: "#{g1_3.name}/#{unique_id}", overview: unique_id }

  let!(:layout) { create_cms_layout }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "no roots" do
      let!(:node) { create :lsorg_node_node, layout_id: layout.id }

      it "#index" do
        visit node.url
        expect(page).to have_css(".lsorg-groups")
      end
    end

    context "roots g1" do
      let!(:node) { create :lsorg_node_node, layout_id: layout.id, root_group_ids: [g1.id] }
      let!(:inquiry_form) { create :inquiry_node_form }

      before do
        site.inquiry_form = inquiry_form
        site.update!
      end

      it "#index" do
        visit node.url
        within ".lsorg-groups" do
          expect(page).to have_css("h2.#{g1_1.basename}", text: g1_1.trailing_name)
          within "table.#{g1_1.basename}.children" do
            expect(page).to have_text g1_1_1.trailing_name
            expect(page).to have_text g1_1_2.trailing_name

            expect(page).to have_text g1_1_1.overview
            expect(page).to have_text g1_1_2.overview

            expect(page).to have_css("a[href=\"#{inquiry_form.url}?group=#{g1_1_1.id}\"]")
            expect(page).to have_css("a[href=\"#{inquiry_form.url}?group=#{g1_1_2.id}\"]")
          end

          expect(page).to have_css("h2.#{g1_2.basename}", text: g1_2.trailing_name)
          within "table.#{g1_2.basename}.children" do
            expect(page).to have_text g1_2_1.trailing_name
            expect(page).to have_text g1_2_2.trailing_name

            expect(page).to have_text g1_2_1.overview
            expect(page).to have_text g1_2_2.overview

            expect(page).to have_css("a[href=\"#{inquiry_form.url}?group=#{g1_2_1.id}\"]")
            expect(page).to have_css("a[href=\"#{inquiry_form.url}?group=#{g1_2_2.id}\"]")
          end

          expect(page).to have_css("h2.#{g1_3.basename}", text: g1_3.trailing_name)
          within "table.#{g1_3.basename}.children" do
            expect(page).to have_text g1_3_1.trailing_name
            expect(page).to have_text g1_3_2.trailing_name

            expect(page).to have_text g1_3_1.overview
            expect(page).to have_text g1_3_2.overview

            expect(page).to have_css("a[href=\"#{inquiry_form.url}?group=#{g1_3_1.id}\"]")
            expect(page).to have_css("a[href=\"#{inquiry_form.url}?group=#{g1_3_2.id}\"]")
          end
        end
      end
    end
  end
end
