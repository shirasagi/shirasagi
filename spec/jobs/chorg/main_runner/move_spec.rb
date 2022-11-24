require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with move" do
    let(:group) { create(:revision_new_group) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:move_changeset, revision_id: revision.id, source: group) }

    context "with Article::Page" do
      let(:page) { create(:revision_page, cur_site: site, group: group) }

      it do
        # ensure create models
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.where(name: group.name).first).to be_nil
        expect(Cms::Group.where(id: group.id).first.name).to eq changeset.destinations.first["name"]
        expect(Cms::Group.where(id: group.id).first.contact_email).to eq changeset.destinations.first["contact_email"]
        expect(Cms::Group.where(id: group.id).first.contact_tel).to eq changeset.destinations.first["contact_tel"]
        expect(Cms::Group.where(id: group.id).first.contact_fax).to eq changeset.destinations.first["contact_fax"]
        expect(Cms::Group.where(id: group.id).first.contact_link_url).to eq changeset.destinations.first["contact_link_url"]
        expect(Cms::Group.where(id: group.id).first.contact_link_name).to eq changeset.destinations.first["contact_link_name"]
        # ldap_dn is expected not to be changed.
        expect(Cms::Group.where(id: group.id).first.ldap_dn).to eq group.ldap_dn
        # check page
        save_filename = page.filename
        page.reload
        expect(page.group_ids).to eq [ group.id ]
        expect(page.filename).to eq save_filename
        expect(page.contact_group_id).to eq group.id
        expect(page.contact_email).to eq changeset.destinations.first["contact_email"]
        expect(page.contact_tel).to eq changeset.destinations.first["contact_tel"]
        expect(page.contact_fax).to eq changeset.destinations.first["contact_fax"]
        expect(page.contact_link_url).to eq changeset.destinations.first["contact_link_url"]
        expect(page.contact_link_name).to eq changeset.destinations.first["contact_link_name"]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['changes']).to include('name')
        expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[1]['class']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq '1'
        expect(task.entity_logs[1]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
      end
    end

    context "with only move name" do
      let(:group) { create(:revision_new_group) }
      let(:revision) { create(:revision, site_id: site.id) }
      let(:changeset) { create(:move_changeset_only_name, revision_id: revision.id, source: group) }

      context "with Article::Page" do
        let(:page) { create(:revision_page, cur_site: site, group: group) }

        it do
          # ensure create models
          expect(changeset).not_to be_nil
          expect(page).not_to be_nil
          # execute
          job = described_class.bind(site_id: site, task_id: task)
          expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

          # check for job was succeeded
          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(Cms::Group.where(name: group.name).first).to be_nil
          expect(Cms::Group.where(id: group.id).first.name).to eq changeset.destinations.first["name"]
          # these attributes are expected not to be changed.
          expect(Cms::Group.where(id: group.id).first.contact_email).to eq group.contact_email
          expect(Cms::Group.where(id: group.id).first.contact_tel).to eq group.contact_tel
          expect(Cms::Group.where(id: group.id).first.contact_fax).to eq group.contact_fax
          expect(Cms::Group.where(id: group.id).first.contact_link_url).to eq group.contact_link_url
          expect(Cms::Group.where(id: group.id).first.contact_link_name).to eq group.contact_link_name
          expect(Cms::Group.where(id: group.id).first.ldap_dn).to eq group.ldap_dn
          # check page
          save_filename = page.filename
          page.reload
          expect(page.group_ids).to eq [ group.id ]
          expect(page.filename).to eq save_filename
          expect(page.contact_group_id).to eq group.id
          expect(page.contact_email).to eq group.contact_email
          expect(page.contact_tel).to eq group.contact_tel
          expect(page.contact_fax).to eq group.contact_fax
          expect(page.contact_link_url).to eq group.contact_link_url
          expect(page.contact_link_name).to eq group.contact_link_name

          task.reload
          expect(task.state).to eq 'completed'
          expect(task.entity_logs.count).to eq 1
          expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['id']).to eq group.id.to_s
          expect(task.entity_logs[0]['changes']).to include("name")
        end
      end
    end

    context "with workflow approving Article::Page" do
      let(:user1) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
               group_ids: [group.id], cms_role_ids: [cms_role.id])
      end
      let(:user2) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
               group_ids: [group.id], cms_role_ids: [cms_role.id])
      end
      let(:page) do
        page = build(:revision_page, cur_site: site, group: group, workflow_user_id: user1.id,
               workflow_state: "request",
               workflow_comment: "",
               workflow_approvers: [{level: 1, user_id: user2.id, state: "request", comment: ""}],
               workflow_required_counts: [false])
        page.cur_site = site
        page.save!
        page
      end

      it do
        # ensure create models
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user1)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.where(name: group.name).first).to be_nil
        expect(Cms::Group.where(id: group.id).first.name).to eq changeset.destinations.first["name"]
        # check page
        save_filename = page.filename
        page.reload
        expect(page.group_ids).to eq [ group.id ]
        expect(page.filename).to eq save_filename
        expect(page.contact_group_id).to eq group.id
        expect(page.contact_email).to eq changeset.destinations.first["contact_email"]
        expect(page.contact_tel).to eq changeset.destinations.first["contact_tel"]
        expect(page.contact_fax).to eq changeset.destinations.first["contact_fax"]
        expect(page.contact_link_url).to eq changeset.destinations.first["contact_link_url"]
        expect(page.contact_link_name).to eq changeset.destinations.first["contact_link_name"]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['changes']).to include(
          'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
        expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[1]['class']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq '1'
        expect(task.entity_logs[1]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
      end
    end

    context 'with overwrite some fields' do
      context "with Article::Page" do
        let(:group) { create(:cms_group, name: "組織変更/グループ#{unique_id}") }
        let(:page) { create(:revision_page, cur_site: site, group: group, filename: unique_id) }

        it do
          # ensure create models
          expect(changeset).not_to be_nil
          expect(page).not_to be_nil
          # execute
          job = described_class.bind(site_id: site, task_id: task)
          expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

          # check for job was succeeded
          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(Cms::Group.where(name: group.name).first).to be_nil
          expect(Cms::Group.where(id: group.id).first.name).to eq changeset.destinations.first["name"]
          expect(Cms::Group.where(id: group.id).first.contact_email).to eq changeset.destinations.first["contact_email"]
          expect(Cms::Group.where(id: group.id).first.contact_tel).to eq changeset.destinations.first["contact_tel"]
          expect(Cms::Group.where(id: group.id).first.contact_fax).to eq changeset.destinations.first["contact_fax"]
          expect(Cms::Group.where(id: group.id).first.contact_link_url).to eq changeset.destinations.first["contact_link_url"]
          expect(Cms::Group.where(id: group.id).first.contact_link_name).to eq changeset.destinations.first["contact_link_name"]
          # ldap_dn is expected not to be changed.
          expect(Cms::Group.where(id: group.id).first.ldap_dn).to eq group.ldap_dn
          # check page
          save_filename = page.filename
          page.reload
          expect(page.group_ids).to eq [ group.id ]
          expect(page.filename).to eq save_filename
          expect(page.contact_group_id).to eq group.id
          expect(page.contact_email).to eq changeset.destinations.first["contact_email"]
          expect(page.contact_tel).to eq changeset.destinations.first["contact_tel"]
          expect(page.contact_fax).to eq changeset.destinations.first["contact_fax"]
          expect(page.contact_link_url).to eq changeset.destinations.first["contact_link_url"]
          expect(page.contact_link_name).to eq changeset.destinations.first["contact_link_name"]

          task.reload
          expect(task.state).to eq 'completed'
          expect(task.entity_logs.count).to eq 2
          expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['id']).to eq group.id.to_s
          expect(task.entity_logs[0]['changes']).to include(
            'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
          expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
          expect(task.entity_logs[1]['class']).to eq 'Article::Page'
          expect(task.entity_logs[1]['id']).to eq '1'
          expect(task.entity_logs[1]['changes']).to include(
            'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
        end
      end
    end
  end
end
