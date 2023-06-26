require 'spec_helper'

describe Cms::AllContentsImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create(:cms_layout, cur_site: site) }
  let!(:cate) { create(:category_node_node, cur_site: site) }

  let!(:group0) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }
  let!(:group1) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }
  let!(:group2) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }

  before do
    csv_data = Cms::AllContent.new(site: site, criteria: criteria).enum_csv(encoding: "UTF-8").to_a.join
    ss_file = tmp_ss_file(contents: csv_data)
    expect do
      described_class.bind(site_id: site.id, user_id: user.id).perform_now(ss_file.id)
    end.to output.to_stdout
  end

  context "when importing article/node" do
    let!(:node) do
      create(:article_node_page, cur_site: site, layout_id: layout.id, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
    end

    context "with basic info" do
      let(:name) { "name-#{unique_id}" }
      let(:index_name) { "index_name-#{unique_id}" }
      let(:filename) { "filename-#{unique_id}" }
      let!(:layout1) { create(:cms_layout, cur_site: site) }
      let(:criteria) do
        node2 = Cms::Node.find(node.id)
        node2.name = name
        node2.index_name = index_name
        node2.filename = filename
        node2.layout = layout1
        [ node2 ]
      end

      it do
        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Cms::Node.find(node.id).tap do |updated_node|
          expect(updated_node.name).to eq name
          expect(updated_node.index_name).to eq index_name
          # filename is unable to import
          expect(updated_node.filename).not_to eq filename
          expect(updated_node.filename).to eq node.filename
          expect(updated_node.layout_id).to eq layout1.id
        end
      end
    end

    context "with cms/addon/node_setting" do
      let!(:page_layout1) { create(:cms_layout, cur_site: site) }
      let(:order) { rand(10..20) }
      let(:shortcut) { %w(show hide).sample }
      let(:view_route) { %w(article/page category/node category/page cms/node cms/page event/page).sample }
      let(:criteria) do
        node2 = Cms::Node.find(node.id)
        node2.page_layout = page_layout1
        node2.order = order
        node2.shortcut = shortcut
        node2.view_route = view_route
        [ node2 ]
      end

      it do
        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Cms::Node.find(node.id).tap do |updated_node|
          expect(updated_node.page_layout).to eq page_layout1
          expect(updated_node.order).to eq order
          expect(updated_node.shortcut).to eq shortcut
          expect(updated_node.view_route).to eq view_route
        end
      end
    end

    context "with cms/addon/meta" do
      let(:keywords) { Array.new(2) { "keyword-#{unique_id}" } }
      let(:description) { "description-#{unique_id}" }
      let(:summary_html) { "<p>#{unique_id}</p>" }
      let(:criteria) do
        node2 = Cms::Node.find(node.id)
        node2.keywords = keywords
        node2.description = description
        node2.summary_html = summary_html
        [ node2 ]
      end

      it do
        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Cms::Node.find(node.id).tap do |updated_node|
          expect(updated_node.keywords).to eq keywords
          expect(updated_node.description).to eq description
          expect(updated_node.summary_html).to eq summary_html
        end
      end
    end

    context "with event/addon/page_list" do
      let(:conditions) { Array.new(2) { "condition-#{unique_id}" } }
      let(:sort) { [ "name", "filename", "created", "updated -1", "released -1", "order", "order -1", "event_dates" ].sample }
      let(:limit) { rand(1..20) }
      let(:new_days) { rand(1..20) }
      let(:loop_format) { %w(shirasagi liquid).sample }
      let(:upper_html) { Array.new(2) { "<p>upper_html-#{unique_id}</p>" } }
      let(:loop_html) { Array.new(2) { "<p>loop_html-#{unique_id}</p>" } }
      let(:lower_html) { Array.new(2) { "<p>lower_html-#{unique_id}</p>" } }
      let(:loop_liquid) { Array.new(2) { "<p>loop_liquid-#{unique_id}</p>" } }
      let(:no_items_display_state) { %w(show hide).sample }
      let(:substitute_html) { Array.new(2) { "<p>substitute_html-#{unique_id}</p>" } }

      let(:criteria) do
        node2 = Cms::Node.find(node.id)
        node2.conditions = conditions
        node2.sort = sort
        node2.limit = limit
        node2.new_days = new_days
        node2.loop_format = loop_format
        node2.upper_html = upper_html.join("\r\n")
        node2.loop_html = loop_html.join("\r\n")
        node2.lower_html = lower_html.join("\r\n")
        node2.loop_liquid = loop_liquid.join("\r\n")
        node2.no_items_display_state = no_items_display_state
        node2.substitute_html = substitute_html.join("\r\n")
        [ node2 ]
      end

      it do
        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Cms::Node.find(node.id).tap do |updated_node|
          expect(updated_node.conditions).to eq conditions
          expect(updated_node.sort).to eq sort
          expect(updated_node.limit).to eq limit
          expect(updated_node.new_days).to eq new_days
          expect(updated_node.loop_format).to eq loop_format
          expect(updated_node.upper_html).to eq upper_html.join("\r\n")
          expect(updated_node.loop_html).to eq loop_html.join("\r\n")
          expect(updated_node.lower_html).to eq lower_html.join("\r\n")
          expect(updated_node.loop_liquid).to eq loop_liquid.join("\r\n")
          expect(updated_node.no_items_display_state).to eq no_items_display_state
          expect(updated_node.substitute_html).to eq substitute_html.join("\r\n")
        end
      end
    end

    context "with category/addon/setting" do
      let!(:cate1) { create(:category_node_node, cur_site: site) }
      let(:criteria) do
        node2 = Cms::Node.find(node.id)
        node2.st_category_ids = [ cate1.id ]
        [ node2 ]
      end

      it do
        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Cms::Node.find(node.id).tap do |updated_node|
          expect(updated_node.st_category_ids).to eq [cate1.id]
        end
      end
    end

    context "with cms/addon/release" do
      let(:state) { %w(public closed).sample }
      let(:released_type) { %w(fixed same_as_updated same_as_created same_as_first_released).sample }
      let(:released) { Time.zone.now.beginning_of_hour - 1.day }
      let(:criteria) do
        node2 = Cms::Node.find(node.id)
        node2.state = state
        node2.released_type = released_type
        node2.released = released
        [ node2 ]
      end

      it do
        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Cms::Node.find(node.id).tap do |updated_node|
          expect(updated_node.state).to eq state
          expect(updated_node.released_type).to eq released_type
          if released_type == "fixed"
            expect(updated_node.released).to eq released
          end
        end
      end
    end

    context "with cms/addon/group_permission" do
      let(:criteria) do
        node2 = Cms::Node.find(node.id)
        node2.group_ids = [ group1.id ]
        [ node2 ]
      end

      it do
        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Cms::Node.find(node.id).tap do |updated_node|
          expect(updated_node.group_ids).to eq [group1.id]
        end
      end
    end
  end

  context "when importing article/page" do
    let!(:layout) { create(:cms_layout, cur_site: site) }
    let!(:layout1) { create(:cms_layout, cur_site: site) }
    let!(:cate) { create(:category_node_node, cur_site: site) }
    let!(:cate1) { create(:category_node_node, cur_site: site) }
    let!(:node) do
      create(:article_node_page, cur_site: site, layout_id: layout.id, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
    end
    let!(:page) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, category_ids: [ cate.id ],
        group_ids: [ cms_group.id ]
      )
    end
    let(:filename) { "filename-#{unique_id}.html" }
    let(:released) { Time.zone.now.beginning_of_hour - 1.day }
    let(:release_date) { Time.zone.now.beginning_of_hour + 1.hour }
    let(:close_date) { Time.zone.now.beginning_of_hour + 13.hours }
    let(:criteria) do
      page2 = page.dup
      page2.id = page.id
      page2.layout = layout1
      page2.filename = filename
      page2.category_ids = [ cate1.id ]
      page2.released = released
      page2.release_date = release_date
      page2.close_date = close_date
      page2.group_ids = [ group1.id ]
      [ page2 ]
    end

    it do
      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.find(page.id).tap do |updated_page|
        expect(updated_page.name).to eq page.name
        expect(updated_page.index_name).to eq page.index_name
        expect(updated_page.filename).to eq page.filename
        expect(updated_page.layout_id).to eq layout1.id
        expect(updated_page.keywords).to eq page.keywords
        expect(updated_page.description).to eq page.description
        expect(updated_page.summary_html).to eq page.summary_html
        expect(updated_page.category_ids).to eq [cate1.id]
        expect(updated_page.group_ids).to eq [group1.id]
        expect(updated_page.status).to eq 'ready'
        expect(updated_page.released).to eq released
        expect(updated_page.release_date).to eq release_date
        expect(updated_page.close_date).to eq close_date
      end
    end
  end

  context "when importing other site objects to article/page" do
    let(:layout) { create(:cms_layout, cur_site: site) }
    let(:cate) { create(:category_node_node, cur_site: site) }
    let(:node) do
      create(:article_node_page, cur_site: site, layout_id: layout.id, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
    end
    let(:page) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, category_ids: [ cate.id ],
        group_ids: [ cms_group.id ]
      )
    end

    let(:group_x) { Cms::Group.create!(name: unique_id) }
    let(:site_x) do
      create(:cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp", group_ids: [ group_x.id ])
    end
    let(:layout_x) { create(:cms_layout, cur_site: site_x) }
    let(:cate_x) { create(:category_node_node, cur_site: site_x) }
    let(:criteria) do
      page2 = page.dup
      page2.id = page.id
      page2.layout = layout_x
      page2.category_ids = [ cate_x.id ]
      page2.group_ids = [ group_x.id ]
      [ page2 ]
    end

    it do
      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      # all references are set to empty because other site's objects is unable to import.
      Cms::Page.find(page.id).tap do |updated_page|
        expect(updated_page.name).to eq page.name
        expect(updated_page.index_name).to eq page.index_name
        expect(updated_page.layout_id).to be_blank
        expect(updated_page.category_ids).to be_blank
        expect(updated_page.group_ids).to be_blank
      end
    end
  end
end
