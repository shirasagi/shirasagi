require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context 'with content csv' do
    let(:revision) { create(:revision, site_id: site.id) }
    let!(:changeset1) { create(:add_changeset, revision_id: revision.id, destinations: [{'name' => 'A/B/C'}]) }
    let!(:changeset2) { create(:add_changeset, revision_id: revision.id, destinations: [{'name' => 'A/B/D'}]) }

    let(:layout) { create(:cms_layout, cur_site: site) }
    let(:cate) { create(:category_node_node, cur_site: site) }
    let(:node) do
      create(:article_node_page, cur_site: site, layout_id: layout.id, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
    end
    let(:data) { create(:cms_all_content, node_id: node.id, route: node.route) }

    let!(:g1) { create(:cms_group, name: "A", order: 10) }
    let!(:g2) { create(:cms_group, name: "A/B", order: 20) }
    let!(:r1) { create(:cms_role, cur_site: site, name: "all") }
    let!(:r2) { create(:cms_role, cur_site: site, name: "edit") }

    before do
      site.add_to_set(group_ids: [g1.id, g2.id])

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

        revision.in_content_csv_file = temp
        revision.save!
      end
    end

    it do
      # before chorg, there are no users
      expect { Cms::User.find_by(uid: 'import_sys') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_admin') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_user1') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_user2') }.to raise_error Mongoid::Errors::DocumentNotFound

      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 2, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end
end
