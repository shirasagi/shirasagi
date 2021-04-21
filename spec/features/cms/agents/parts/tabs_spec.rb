require 'spec_helper'

describe "cms_agents_parts_tabs", type: :feature, dbscope: :example do
  # default site
  let(:site) { cms_site }
  let(:layout) { create_cms_layout part, cur_site: site }
  let(:node) { create :cms_node, cur_site: site, layout_id: layout.id }
  let(:node2) { create :cms_node_node, cur_site: site }
  let(:node3) { create :cms_node_page, cur_site: site }

  # sub-site
  let(:site1) { create(:cms_site_subdir, parent: site) }
  let(:site1_node1) { create :cms_node_page, cur_site: site1, filename: node3.filename }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "with no setting" do
      let(:part) { create :cms_part_tabs, conditions: [node2.filename, node3.filename, "#{site1.host}:#{site1_node1.filename}"] }
      let!(:node2_page1) { create :cms_page, cur_site: site, cur_node: node2 }
      let!(:node3_page1) { create :cms_page, cur_site: site, cur_node: node3 }
      let!(:site1_node1_page1) { create :cms_page, cur_site: site1, cur_node: site1_node1 }

      it "#index" do
        visit node.url
        expect(status_code).to eq 200

        within ".tabs" do
          expect(all(".tab").size).to eq 3

          within "#cms-tab-#{part.id}-0" do
            expect(page).to have_css("h2", text: node2.name)
            expect(page).to have_css("article header h3 a", text: node2_page1.name)
          end

          within "#cms-tab-#{part.id}-1" do
            expect(page).to have_css("h2", text: node3.name)
            expect(page).to have_css("article header h3 a", text: node3_page1.name)
          end

          within "#cms-tab-#{part.id}-2" do
            expect(page).to have_css("h2", text: site1_node1.name)
            expect(page).to have_css("article header h3 a", text: site1_node1_page1.name)
          end
        end
      end
    end

    context "with loop html" do
      let(:part) do
        create(:cms_part_tabs,
          conditions: [node2.filename, node3.filename, "#{site1.host}:#{site1_node1.filename}"],
          loop_html: '<s>#{url}</s>'
        )
      end
      let!(:node2_page1) { create :cms_page, cur_site: site, cur_node: node2 }
      let!(:node2_page2) { create :cms_page, cur_site: site, cur_node: node2 }
      let!(:site1_node1_page1) { create :cms_page, cur_site: site1, cur_node: site1_node1 }

      it "#index" do
        visit node.url
        expect(status_code).to eq 200

        within ".tabs" do
          expect(all(".tab").size).to eq 3

          within "#cms-tab-#{part.id}-0" do
            expect(page).to have_css("h2", text: node2.name)
            expect(page).to have_css("s", text: node2_page1.url)
            expect(page).to have_css("s", text: node2_page2.url)
          end

          within "#cms-tab-#{part.id}-2" do
            expect(page).to have_css("h2", text: site1_node1.name)
            expect(page).to have_css("s", text: site1_node1_page1.url)
          end
        end
      end
    end

    context "with substitute html" do
      let(:part) do
        create(:cms_part_tabs,
          conditions: [node2.filename, node3.filename, "#{site1.host}:#{site1_node1.filename}"],
          loop_html: '<s>#{url}</s>',
          substitute_html: '<s>empty</s>'
        )
      end
      let!(:node2_page1) { create :cms_page, cur_site: site, cur_node: node2 }

      it "#index" do
        visit node.url
        expect(status_code).to eq 200

        within ".tabs" do
          expect(all(".tab").size).to eq 3

          within "#cms-tab-#{part.id}-0" do
            expect(page).to have_css("h2", text: node2.name)
            expect(page).to have_css("s", text: node2_page1.url)
            expect(page).to have_no_css("s", text: "empty")
          end

          within "#cms-tab-#{part.id}-1" do
            expect(page).to have_css("h2", text: node3.name)
            expect(page).to have_css("s", text: "empty")
          end

          within "#cms-tab-#{part.id}-2" do
            expect(page).to have_css("h2", text: site1_node1.name)
            expect(page).to have_css("s", text: "empty")
          end
        end
      end
    end
  end
end
