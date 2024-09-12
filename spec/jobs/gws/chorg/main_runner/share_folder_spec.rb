require 'spec_helper'

describe Gws::Chorg::MainRunner, dbscope: :example do
  let!(:site) { create(:gws_revision_root_group) }
  let!(:task) { Gws::Chorg::Task.create!(name: unique_id, group: site) }
  let(:job_opts) { {} }

  context 'with move' do
    let!(:source_group) { create(:gws_revision_new_group, order: 10) }
    let(:destination) do
      { name: "#{site.name}/#{unique_id}" }.with_indifferent_access
    end
    let!(:user1) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [source_group.id]) }
    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset) { create(:gws_move_changeset, revision_id: revision.id, source: source_group, destinations: [ destination ]) }
    let!(:folder1) do
      create(:gws_share_folder, cur_site: site, cur_user: user1, group_ids: [source_group.id])
    end
    let!(:folder2) do
      create(:gws_share_folder, cur_site: site, cur_user: user1, group_ids: [source_group.id])
    end
    let!(:folder3) do
      create(:gws_share_folder, cur_site: site, cur_user: user1, name: source_group.trailing_name, group_ids: [source_group.id])
    end

    before do
      # 親フォルダーのIDを最も高く構成する
      folder1.update!(name: "#{folder3.name}/#{folder1.name}")
      folder2.update!(name: "#{folder3.name}/#{folder2.name}")
    end

    it do
      # execute
      job = described_class.bind(site_id: site.id, user_id: user1.id, task_id: task.id)
      expect { ss_perform_now(job, revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).not_to include(/ERROR/, /WARN/)
      end

      new_group = Gws::Group.where(name: changeset.destinations.first['name']).first
      expect(new_group.active?).to be_truthy
      expect(new_group.id).to eq source_group.id

      Gws::Share::Folder.find(folder1.id).tap do |folder_after_chorg|
        expect(folder_after_chorg.name).to start_with new_group.trailing_name
        expect(folder_after_chorg.group_ids).to eq [new_group.id]
      end
      Gws::Share::Folder.find(folder2.id).tap do |folder_after_chorg|
        expect(folder_after_chorg.name).to start_with new_group.trailing_name
        expect(folder_after_chorg.group_ids).to eq [new_group.id]
      end
      Gws::Share::Folder.find(folder3.id).tap do |folder_after_chorg|
        expect(folder_after_chorg.name).to eq new_group.trailing_name
        expect(folder_after_chorg.group_ids).to eq [new_group.id]
      end
    end
  end
end
