require 'spec_helper'

describe Cms::AllContentsImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  let!(:group0) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }
  let!(:group1) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }
  let!(:group2) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }

  before do
    Dir.mktmpdir do |dir|
      name = "#{unique_id}.csv"
      filename = "#{dir}/#{name}"

      temp = Fs::UploadedFile.new("spec", dir)
      temp.binmode
      Cms::AllContent.new(site: site, criteria: criteria).enum_csv(encoding: "Shift_JIS").tap do |enumerable|
        temp.write enumerable.to_a.join
      end
      temp.flush
      temp.rewind
      temp.original_filename = filename
      temp.content_type = ::Fs.content_type(name)

      ss_file = SS::TempFile.new
      ss_file.name = name
      ss_file.in_file = temp
      ss_file.save!

      expect do
        described_class.bind(site_id: site, user_id: user).perform_now(ss_file.id)
      end.to output.to_stdout
    end
  end

  context "when importing article/node" do
    let!(:layout) { create(:cms_layout, cur_site: site) }
    let!(:cate) { create(:category_node_node, cur_site: site) }
    let!(:node) do
      create(:article_node_page, cur_site: site, layout_id: layout.id, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
    end
    let!(:layout1) { create(:cms_layout, cur_site: site) }
    let!(:cate1) { create(:category_node_node, cur_site: site) }
    let(:released) { Time.zone.now.beginning_of_hour - 1.day }
    let(:criteria) do
      node2 = node.dup
      node2.id = node.id
      node2.layout = layout1
      node2.st_category_ids = [ cate1.id ]
      node2.released = released
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
        expect(updated_node.name).to eq node.name
        expect(updated_node.index_name).to eq node.index_name
        expect(updated_node.filename).to eq node.filename
        expect(updated_node.layout_id).to eq layout1.id
        expect(updated_node.keywords).to eq node.keywords
        expect(updated_node.description).to eq node.description
        expect(updated_node.summary_html).to eq node.summary_html
        expect(updated_node.conditions).to eq node.conditions
        expect(updated_node.st_category_ids).to eq [cate1.id]
        expect(updated_node.sort).to eq node.sort
        expect(updated_node.limit).to eq node.limit
        expect(updated_node.upper_html).to eq node.upper_html
        expect(updated_node.loop_html).to eq node.loop_html
        expect(updated_node.lower_html).to eq node.lower_html
        expect(updated_node.new_days).to eq node.new_days
        expect(updated_node.group_ids).to eq [group1.id]
        expect(updated_node.status).to eq node.status
        expect(updated_node.released).to eq released
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
    let(:release_date) { Time.zone.now.beginning_of_hour - 23.hours }
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
        expect(updated_page.status).to eq page.status
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
