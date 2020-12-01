require 'spec_helper'

describe Cms::AllContentsImportJob, dbscope: :example do
  let!(:site) { cms_site }

  let!(:group0) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }
  let!(:group1) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }
  let!(:group2) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }

  let(:states_dic) { Hash[I18n.t("ss.options.state").map { |key, value| [ value, key.to_s ] }] }

  before do
    Dir.mktmpdir do |dir|
      name = "#{unique_id}.csv"
      filename = "#{dir}/#{name}"

      temp = Fs::UploadedFile.new("spec", dir)
      temp.binmode
      temp.write Cms::AllContent.encode_sjis(Cms::AllContent.header.to_csv)
      temp.write Cms::AllContent.encode_sjis(Cms::AllContent::FIELDS_DEF.map { |key, *_| data[key] }.to_csv)
      temp.flush
      temp.rewind
      temp.original_filename = filename
      temp.content_type = ::Fs.content_type(name)

      ss_file = SS::TempFile.new
      ss_file.name = name
      ss_file.in_file = temp
      ss_file.save!

      described_class.bind(site_id: site).perform_now(ss_file.id)
    end
  end

  context "when importing article/node" do
    let(:layout) { create(:cms_layout, cur_site: site) }
    let(:cate) { create(:category_node_node, cur_site: site) }
    let(:node) do
      create(:article_node_page, cur_site: site, layout_id: layout.id, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
    end
    let(:layout1) { create(:cms_layout, cur_site: site) }
    let(:other_node) { create(:article_node_page, cur_site: site, group_ids: [ cms_group.id ]) }
    let(:cate1) { create(:category_node_node, cur_site: site) }
    let(:released) { Time.zone.now.beginning_of_hour - 1.day }
    let(:data) do
      create(
        :cms_all_content, node_id: node.id, route: node.route, layout: layout1.filename, conditions: other_node.filename,
        category_ids: "#{cate1.filename}(#{cate1.name})", group_names: group1.name, released: released
      )
    end

    it do
      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      node.reload
      expect(node.name).to eq data.name
      expect(node.index_name).to eq data.index_name
      expect(node.filename).to eq data.filename
      expect(node.layout_id).to eq layout1.id
      expect(node.keywords).to eq [ data.keywords ]
      expect(node.description).to eq data.description
      expect(node.summary_html).to eq data.summary_html
      expect(node.conditions).to eq [ data.conditions ]
      expect(node.category_ids).to eq [cate1.id]
      expect(node.sort).to eq data.sort
      expect(node.limit).to eq data.limit
      expect(node.upper_html).to eq data.upper_html
      expect(node.loop_html).to eq data.loop_html
      expect(node.lower_html).to eq data.lower_html
      expect(node.new_days).to eq data.new_days
      expect(node.group_ids).to eq [group1.id]
      expect(node.status).to eq states_dic[data.status]
      expect(node.released).to eq released
    end
  end

  context "when importing article/page" do
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
    let(:layout1) { create(:cms_layout, cur_site: site) }
    let(:cate1) { create(:category_node_node, cur_site: site) }
    let(:released) { Time.zone.now.beginning_of_hour - 1.day }
    let(:release_date) { Time.zone.now.beginning_of_hour - 23.hours }
    let(:close_date) { Time.zone.now.beginning_of_hour + 13.hours }
    let(:data) do
      create(
        :cms_all_content, page_id: page.id, route: page.route, layout: layout1.filename, filename: "filename-#{unique_id}.html",
        category_ids: "#{cate1.filename}(#{cate1.name})", group_names: group1.name,
        released: released, release_date: release_date, close_date: close_date
      )
    end

    it do
      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      page.reload
      expect(page.name).to eq data.name
      expect(page.index_name).to eq data.index_name
      expect(page.filename).to eq data.filename
      expect(page.layout_id).to eq layout1.id
      expect(page.keywords).to eq [ data.keywords ]
      expect(page.description).to eq data.description
      expect(page.summary_html).to eq data.summary_html
      expect(page.category_ids).to eq [cate1.id]
      expect(page.group_ids).to eq [group1.id]
      expect(page.status).to eq states_dic[data.status]
      expect(page.released).to eq released
      expect(page.release_date).to eq release_date
      expect(page.close_date).to eq close_date
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
    let(:data) do
      create(
        :cms_all_content, page_id: page.id, route: page.route,
        layout: layout_x.filename, category_ids: "#{cate_x.filename}(#{cate_x.name})", group_names: group_x.name
      )
    end

    it do
      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      # all references are set to empty because other site's objects is unable to import.
      page.reload
      expect(page.name).to eq data.name
      expect(page.index_name).to eq data.index_name
      expect(page.layout_id).to be_nil
      expect(page.category_ids).to eq []
      expect(page.group_ids).to eq []
    end
  end
end
