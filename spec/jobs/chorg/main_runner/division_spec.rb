require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with division" do
    context "with Article::Page" do
      let(:group0) { create(:revision_new_group) }
      let(:group1) do
        OpenStruct.new(
          name: "組織変更/グループ#{unique_id}", contact_email: "#{unique_id}@example.jp", contact_tel: unique_tel,
          contact_fax: unique_tel, contact_link_url: "/#{unique_id}/", contact_link_name: unique_id.to_s,
          ldap_dn: "ou=group,dc=example,dc=jp"
        )
      end
      let(:group2) do
        OpenStruct.new(
          name: "組織変更/グループ#{unique_id}", contact_email: "#{unique_id}@example.jp", contact_tel: unique_tel,
          contact_fax: unique_tel, contact_link_url: "/#{unique_id}/", contact_link_name: unique_id.to_s,
          ldap_dn: "ou=group,dc=example,dc=jp"
        )
      end
      let(:user) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group0.id]) }
      let(:revision) { create(:revision, site_id: site.id) }
      let(:changeset) do
        create(:division_changeset, revision_id: revision.id, source: group0, destinations: [group1, group2])
      end
      let(:page) { create(:revision_page, cur_site: site, group: group0) }

      it do
        # ensure create models
        expect(user).not_to be_nil
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.where(id: group0.id).first).to be_nil
        expect(Cms::Group.where(name: group0.name).first).to be_nil
        new_group1 = Cms::Group.where(name: changeset.destinations[0]["name"]).first
        expect(new_group1).not_to be_nil
        new_group2 = Cms::Group.where(name: changeset.destinations[1]["name"]).first
        expect(new_group2).not_to be_nil
        # check page
        page.reload
        expect(page.group_ids).to eq [ new_group1.id, new_group2.id ]
        expect(page.contact_group_id).to eq new_group1.id
        expect(page.contact_email).to eq new_group1.contact_email
        expect(page.contact_tel).to eq new_group1.contact_tel
        expect(page.contact_fax).to eq new_group1.contact_fax
        expect(page.contact_link_url).to eq new_group1.contact_link_url
        expect(page.contact_link_name).to eq new_group1.contact_link_name

        user.reload
        expect(user.group_ids).to eq [ new_group1.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 7

        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include('name' => group1[:name], 'contact_email' => group1[:contact_email])

        expect(task.entity_logs[1]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[1]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[1]['creates']).to include('name' => group2[:name], 'contact_email' => group2[:contact_email])

        expect(task.entity_logs[2]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['id']).to eq site.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')

        expect(task.entity_logs[3]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[3]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[3]['id']).to eq site.id.to_s
        expect(task.entity_logs[3]['changes']).to include('group_ids')

        expect(task.entity_logs[4]['model']).to eq 'Cms::User'
        expect(task.entity_logs[4]['class']).to eq 'Cms::User'
        expect(task.entity_logs[4]['id']).to eq user.id.to_s
        expect(task.entity_logs[4]['changes']).to include('group_ids')

        expect(task.entity_logs[5]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[5]['class']).to eq 'Article::Page'
        expect(task.entity_logs[5]['id']).to eq page.id.to_s
        expect(task.entity_logs[5]['changes']).to include("group_ids")

        expect(task.entity_logs[6]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[6]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[6]['id']).to eq group0.id.to_s
        expect(task.entity_logs[6]['deletes']).to include('name')
      end
    end

    context "divide from existing group to existing group" do
      let(:group1) { create(:revision_new_group) }
      let(:group2) { build(:revision_new_group) }
      let(:user) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
      let(:revision) { create(:revision, site_id: site.id) }
      let(:changeset) do
        create(:division_changeset, revision_id: revision.id, source: group1, destinations: [group1, group2])
      end
      let(:page) { create(:revision_page, cur_site: site, group: group1) }

      it do
        # ensure create models
        expect(user).not_to be_nil
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.where(id: group1.id).first).not_to be_nil
        expect(Cms::Group.where(name: group1.name).first).not_to be_nil
        # expect(Cms::Group.where(id: group2.id).first).not_to be_nil
        expect(Cms::Group.where(name: group2.name).first).not_to be_nil

        new_group1 = Cms::Group.where(name: changeset.destinations[0]["name"]).first
        expect(new_group1).not_to be_nil
        new_group2 = Cms::Group.where(name: changeset.destinations[1]["name"]).first
        expect(new_group2).not_to be_nil
        # check page
        page.reload
        expect(page.group_ids).to eq [ new_group1.id, new_group2.id ]
        expect(page.contact_group_id).to eq new_group1.id
        expect(page.contact_email).to eq new_group1.contact_email
        expect(page.contact_tel).to eq new_group1.contact_tel
        expect(page.contact_fax).to eq new_group1.contact_fax
        expect(page.contact_link_url).to eq new_group1.contact_link_url
        expect(page.contact_link_name).to eq new_group1.contact_link_name

        user.reload
        expect(user.group_ids).to eq [ new_group1.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 4
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include('name', 'contact_email')
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
        expect(task.entity_logs[2]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['id']).to eq site.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')
        expect(task.entity_logs[3]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[3]['class']).to eq 'Article::Page'
        expect(task.entity_logs[3]['id']).to eq page.id.to_s
        expect(task.entity_logs[3]['changes']).to include("group_ids")
      end
    end
  end
end
