require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:role) { create(:cms_role_admin, cur_site: site) }
  let!(:user) { create(:cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let!(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context 'with content csv' do
    let(:revision) { create(:revision, site_id: site.id) }
    let!(:changeset1) { create(:add_changeset, revision_id: revision.id, destinations: [{'name' => 'A/B/C'}]) }
    let!(:changeset2) { create(:add_changeset, revision_id: revision.id, destinations: [{'name' => 'A/B/D'}]) }

    let!(:layout) { create(:cms_layout, cur_site: site) }
    let!(:cate) { create(:category_node_node, cur_site: site) }
    let!(:node) do
      Timecop.freeze(now - 2.weeks) do
        node = create(:article_node_page, cur_site: site, layout_id: layout.id, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
        ::FileUtils.rm_rf(node.path)
        Cms::Node.find(node.id)
      end
    end

    let!(:g1) { create(:cms_group, name: "A", order: 10) }
    let!(:g2) { create(:cms_group, name: "A/B", order: 20) }
    let!(:r1) { create(:cms_role, cur_site: site, name: "all") }
    let!(:r2) { create(:cms_role, cur_site: site, name: "edit") }

    let(:name) { "name-#{unique_id}" }
    let(:index_name) { "index_name-#{unique_id}" }
    let(:filename) { "filename-#{unique_id}" }
    let(:keywords) { "keywords-#{unique_id}" }
    let(:description) { "description-#{unique_id}" }
    let(:summary_html) { "summary_html-#{unique_id}" }
    let(:sort) { [ "name", "filename", "created", "updated -1", "released -1", "order" ].sample }
    let(:limit) { rand(1..100) }
    let(:upper_html) { "upper-#{unique_id}" }
    let(:loop_html) { "loop-#{unique_id}" }
    let(:lower_html) { "lower-#{unique_id}" }
    let(:new_days) { rand(10) }
    let(:state) { %w(public closed).sample }

    before do
      site.add_to_set(group_ids: [g1.id, g2.id])

      ss_file = node.dup.then do |node2|
        node2.id = node.id
        node2.name = name
        node2.index_name = index_name
        node2.filename = filename
        node2.keywords = keywords
        node2.description = description
        node2.summary_html = summary_html
        node2.sort = sort
        node2.limit = limit
        node2.upper_html = upper_html
        node2.loop_html = loop_html
        node2.lower_html = lower_html
        node2.new_days = new_days
        node2.state = state

        csv_data = Cms::AllContent.new(site: site, criteria: [ node2 ]).enum_csv(encoding: "UTF-8").to_a.join

        tmp_ss_file(contents: csv_data)
      end

      revision.content_csv_file = ss_file
      revision.save!

      expect(ss_file.owner_item).to eq revision
    end

    it do
      # before chorg, there are no users
      expect { Cms::User.find_by(uid: 'import_sys') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_admin') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_user1') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_user2') }.to raise_error Mongoid::Errors::DocumentNotFound

      job = described_class.bind(site_id: site.id, user_id: user.id, task_id: task.id)
      expect do
        ss_perform_now(job, revision.name, job_opts)
      end.to output(include("[新設] 成功: 2, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Node.find(node.id).tap do |node2|
        expect(node2.name).to eq name
        expect(node2.index_name).to eq index_name
        expect(node2.filename).not_to eq filename
        expect(node2.filename).to eq node.filename
        expect(node2.keywords).to eq [ keywords ]
        expect(node2.description).to eq description
        expect(node2.summary_html).to eq summary_html
        expect(node2.sort).to eq sort
        expect(node2.limit).to eq limit
        expect(node2.upper_html).to eq upper_html
        expect(node2.loop_html).to eq loop_html
        expect(node2.lower_html).to eq lower_html
        expect(node2.new_days).to eq new_days
        expect(node2.state).to eq state
        expect(node2.updated.in_time_zone).to eq node.updated.in_time_zone
      end
    end
  end
end
