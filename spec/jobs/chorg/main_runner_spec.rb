require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with add" do
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:add_changeset, revision_id: revision.id) }

    it do
      expect(changeset).not_to be_nil
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Cms::Group.where(name: changeset.destinations.first["name"]).first).not_to be_nil

      task.reload
      expect(task.state).to eq 'stop'
      expect(task.entity_logs.count).to eq 2
      expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
      expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
      expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
      expect(task.entity_logs[1]['id']).to eq site.id.to_s
      expect(task.entity_logs[1]['changes']).to include('group_ids')
    end
  end

  context "with move" do
    let(:group) { create(:revision_new_group) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:move_changeset, revision_id: revision.id, source: group) }

    context "with Article::Page" do
      let(:page) { create(:revisoin_page, cur_site: site, group: group) }

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
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
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
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['changes']).to include('name')
        expect(task.entity_logs[1]['model']).to eq 'Article::Page'
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
        let(:page) { create(:revisoin_page, cur_site: site, group: group) }

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
            expect(log.logs).to include(include('INFO -- : Started Job'))
            expect(log.logs).to include(include('INFO -- : Completed Job'))
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
          expect(task.state).to eq 'stop'
          expect(task.entity_logs.count).to eq 1
          expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['id']).to eq group.id.to_s
          expect(task.entity_logs[0]['changes']).to include(
            'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
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
        page = build(:revisoin_page, cur_site: site, group: group, workflow_user_id: user1.id,
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
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
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
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['changes']).to include(
          'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
        expect(task.entity_logs[1]['model']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq '1'
        expect(task.entity_logs[1]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
      end
    end

    context 'with overwrite some fields' do
      context "with Article::Page" do
        let(:group) { create(:cms_group, name: "組織変更/グループ#{unique_id}") }
        let(:page) { create(:revisoin_page, cur_site: site, group: group, filename: unique_id) }

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
            expect(log.logs).to include(include('INFO -- : Started Job'))
            expect(log.logs).to include(include('INFO -- : Completed Job'))
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
          expect(task.state).to eq 'stop'
          expect(task.entity_logs.count).to eq 2
          expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['id']).to eq group.id.to_s
          expect(task.entity_logs[0]['changes']).to include(
            'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
          expect(task.entity_logs[1]['model']).to eq 'Article::Page'
          expect(task.entity_logs[1]['id']).to eq '1'
          expect(task.entity_logs[1]['changes']).to include(
            'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
        end
      end
    end
  end

  context "with unify" do
    context "with Article::Page" do
      let(:group1) { create(:revision_new_group) }
      let(:group2) { create(:revision_new_group) }
      let(:user1) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
      let(:user2) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
      let(:revision) { create(:revision, site_id: site.id) }
      let(:changeset) { create(:unify_changeset, revision_id: revision.id, sources: [group1, group2]) }
      let(:page) { create(:revisoin_page, cur_site: site, group: group1) }

      it do
        # ensure create models
        expect(user1).not_to be_nil
        expect(user2).not_to be_nil
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user1)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(Cms::Group.where(id: group1.id).first).to be_nil
        expect(Cms::Group.where(name: group1.name).first).to be_nil
        expect(Cms::Group.where(id: group2.id).first).to be_nil
        expect(Cms::Group.where(name: group2.name).first).to be_nil
        new_group = Cms::Group.where(name: changeset.destinations.first["name"]).first
        expect(new_group).not_to be_nil
        # check page
        page.reload
        expect(page.group_ids).to eq [ new_group.id ]
        expect(page.contact_group_id).to eq new_group.id
        expect(page.contact_email).to eq new_group.contact_email
        expect(page.contact_tel).to eq new_group.contact_tel
        expect(page.contact_fax).to eq new_group.contact_fax
        expect(page.contact_link_url).to eq new_group.contact_link_url
        expect(page.contact_link_name).to eq new_group.contact_link_name

        user1.reload
        expect(user1.group_ids).to eq [new_group.id]
        user2.reload
        expect(user2.group_ids).to eq [new_group.id]

        task.reload
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 7

        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include('name', 'contact_email')

        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')

        expect(task.entity_logs[2]['model']).to eq 'Cms::User'
        expect(task.entity_logs[2]['id']).to eq user1.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')

        expect(task.entity_logs[3]['model']).to eq 'Cms::User'
        expect(task.entity_logs[3]['id']).to eq user2.id.to_s
        expect(task.entity_logs[3]['changes']).to include('group_ids')

        expect(task.entity_logs[4]['model']).to eq 'Article::Page'
        expect(task.entity_logs[4]['id']).to eq '1'
        expect(task.entity_logs[4]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )

        expect(task.entity_logs[5]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[5]['id']).to eq group1.id.to_s
        expect(task.entity_logs[5]['deletes']).to include('name', 'contact_email')

        expect(task.entity_logs[6]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[6]['id']).to eq group2.id.to_s
        expect(task.entity_logs[6]['deletes']).to include('name', 'contact_email')
      end
    end

    context "unify to existing group" do
      let(:group1) { create(:revision_new_group, contact_email: "foobar02@example.jp") }
      let(:group2) { create(:revision_new_group, contact_email: "foobar@example.jp") }
      let(:user1) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
      let(:user2) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
      let(:revision) { create(:revision, site_id: site.id) }
      let(:changeset) do
        create(:unify_changeset, revision_id: revision.id, sources: [group1, group2], destination: group1)
      end
      let(:page) { create(:revisoin_page, cur_site: site, group: group1) }

      it do
        # ensure create models
        expect(user1).not_to be_nil
        expect(user2).not_to be_nil
        expect(changeset).not_to be_nil
        expect(changeset.destinations[0]["name"]).to eq group1.name
        expect(changeset.destinations[0]["contact_email"]).to eq group1.contact_email
        expect(changeset.destinations[0]["contact_tel"]).to eq group1.contact_tel
        expect(changeset.destinations[0]["contact_fax"]).to eq group1.contact_fax
        expect(changeset.destinations[0]["contact_link_url"]).to eq group1.contact_link_url
        expect(changeset.destinations[0]["contact_link_name"]).to eq group1.contact_link_name
        expect(page).not_to be_nil
        expect(page.contact_email).to eq "foobar02@example.jp"
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user1)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        # group1 shoud be exist because group1 is destination_group.
        expect(Cms::Group.where(id: group1.id).first).not_to be_nil
        expect(Cms::Group.where(name: group1.name).first).not_to be_nil
        # group2 shoudn't be exist because group2 is not destination_group.
        expect(Cms::Group.where(id: group2.id).first).to be_nil
        expect(Cms::Group.where(name: group2.name).first).to be_nil
        new_group = Cms::Group.where(name: changeset.destinations.first["name"]).first
        expect(new_group.id).to eq group1.id
        expect(new_group.name).to eq group1.name
        # check page
        page.reload
        expect(page.group_ids).to eq [ new_group.id ]
        expect(page.contact_group_id).to eq new_group.id
        expect(page.contact_email).to eq new_group.contact_email
        expect(page.contact_email).to eq "foobar02@example.jp"
        expect(page.contact_tel).to eq new_group.contact_tel
        expect(page.contact_fax).to eq new_group.contact_fax
        expect(page.contact_link_url).to eq new_group.contact_link_url
        expect(page.contact_link_name).to eq new_group.contact_link_name

        user1.reload
        expect(user1.group_ids).to eq [new_group.id]
        user2.reload
        expect(user2.group_ids).to eq [new_group.id]

        task.reload
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 4
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group1.id.to_s
        expect(task.entity_logs[0]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
        expect(task.entity_logs[2]['model']).to eq 'Cms::User'
        expect(task.entity_logs[2]['id']).to eq user2.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')
        expect(task.entity_logs[3]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[3]['id']).to eq group2.id.to_s
        expect(task.entity_logs[3]['deletes']).to include('name', 'contact_email')
      end
    end
  end

  context "with division" do
    context "with Article::Page" do
      let(:group0) { create(:revision_new_group) }
      let(:group1) { build(:revision_new_group) }
      let(:group2) { build(:revision_new_group) }
      let(:user) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group0.id]) }
      let(:revision) { create(:revision, site_id: site.id) }
      let(:changeset) do
        create(:division_changeset, revision_id: revision.id, source: group0, destinations: [group1, group2])
      end
      let(:page) { create(:revisoin_page, cur_site: site, group: group0) }

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
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
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
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 7

        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include('name' => group1.name, 'contact_email' => group1.contact_email)

        expect(task.entity_logs[1]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[1]['creates']).to include('name' => group2.name, 'contact_email' => group2.contact_email)

        expect(task.entity_logs[2]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['id']).to eq site.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')

        expect(task.entity_logs[3]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[3]['id']).to eq site.id.to_s
        expect(task.entity_logs[3]['changes']).to include('group_ids')

        expect(task.entity_logs[4]['model']).to eq 'Cms::User'
        expect(task.entity_logs[4]['id']).to eq user.id.to_s
        expect(task.entity_logs[4]['changes']).to include('group_ids')

        expect(task.entity_logs[5]['model']).to eq 'Article::Page'
        expect(task.entity_logs[5]['id']).to eq page.id.to_s
        expect(task.entity_logs[5]['changes']).to include(
          'contact_group_id', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )

        expect(task.entity_logs[6]['model']).to eq 'Cms::Group'
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
      let(:page) { create(:revisoin_page, cur_site: site, group: group1) }

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
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
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
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 4
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include('name', 'contact_email')
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
        expect(task.entity_logs[2]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['id']).to eq site.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')
        expect(task.entity_logs[3]['model']).to eq 'Article::Page'
        expect(task.entity_logs[3]['id']).to eq page.id.to_s
        expect(task.entity_logs[3]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
      end
    end
  end

  context "with delete" do
    let(:group) { create(:revision_new_group) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:delete_changeset, revision_id: revision.id, source: group) }

    context 'with default delete_method (disable_if_possible)' do
      it do
        # ensure create models
        expect(changeset).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(Cms::Group.unscoped.where(id: group.id).first.active?).to be_falsey

        task.reload
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 1
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['deletes']).to include('name', 'contact_email')
      end
    end

    context 'with always_delete' do
      before do
        revision.delete_method = 'always_delete'
        revision.save!
      end

      it do
        # ensure create models
        expect(changeset).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(Cms::Group.unscoped.where(id: group.id).first).to be_nil

        task.reload
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 1
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['deletes']).to include('name', 'contact_email')
      end
    end
  end

  context 'with user csv' do
    let(:revision) { create(:revision, site_id: site.id) }
    let!(:changeset1) { create(:add_changeset, revision_id: revision.id, destinations: [{'name' => 'A/B/C'}]) }
    let!(:changeset2) { create(:add_changeset, revision_id: revision.id, destinations: [{'name' => 'A/B/D'}]) }
    let(:csv_file_path) { "#{Rails.root}/spec/fixtures/cms/user/cms_users_1.csv" }

    let!(:g1) { create(:cms_group, name: "A", order: 10) }
    let!(:g2) { create(:cms_group, name: "A/B", order: 20) }
    let!(:r1) { create(:cms_role, cur_site: site, name: "all") }
    let!(:r2) { create(:cms_role, cur_site: site, name: "edit") }

    before do
      site.add_to_set(group_ids: [g1.id, g2.id])

      Fs::UploadedFile.create_from_file(csv_file_path, content_type: 'text/csv') do |f|
        revision.in_user_csv_file = f
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
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      g3 = Cms::Group.find_by(name: 'A/B/C')
      g4 = Cms::Group.find_by(name: 'A/B/D')

      # after chorg, these users should be imported
      Cms::User.find_by(uid: 'import_sys').tap do |u|
        expect(u.name).to eq 'import_sys'
        expect(u.group_ids).to include(g1.id)
        expect(u.cms_role_ids).to include(r1.id, r2.id)
      end

      Cms::User.find_by(uid: 'import_admin').tap do |u|
        expect(u.name).to eq 'import_admin'
        expect(u.group_ids).to include(g3.id)
        expect(u.cms_role_ids).to include(r1.id)
      end

      Cms::User.find_by(uid: 'import_user1').tap do |u|
        expect(u.name).to eq 'import_user1'
        expect(u.group_ids).to include(g3.id, g4.id)
        expect(u.cms_role_ids).to include(r2.id)
      end

      Cms::User.find_by(uid: 'import_user2').tap do |u|
        expect(u.name).to eq 'import_user2'
        expect(u.group_ids).to include(g4.id)
        expect(u.cms_role_ids).to include(r2.id)
      end
    end
  end

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
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end
    end
  end

  # ページの電話番号、ファックス番号、メールアドレスを一括置換する目的で、移動を用いる
  context 'when move is used to update tel, fax, email in all pages' do
    context "non-empty to non-empty" do
      let(:group_attributes) do
        {
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id
        }
      end
      let!(:group1) { create(:revision_new_group, group_attributes) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination) do
        {
          name: group1.name,
          order: "",
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id,
          ldap_dn: ""
        }
      end
      let!(:changeset) do
        create(
          :move_changeset, revision_id: revision.id, source: group1, destinations: [ destination.stringify_keys ]
        )
      end
      # group1 と同じ情報が連絡先にセットされているページ
      let!(:page1) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: group1.contact_email,
          contact_tel: group1.contact_tel,
          contact_fax: group1.contact_fax,
          contact_link_url: group1.contact_link_url,
          contact_link_name: group1.contact_link_name
        )
      end
      # 連絡先が空のページ
      let!(:page2) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: "",
          contact_tel: "",
          contact_fax: "",
          contact_link_url: "",
          contact_link_name: ""
        )
      end
      # 連絡先に異なる情報がセットされているページ
      let!(:page3) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id
        )
      end

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        group1.reload
        expect(group1.contact_email).to eq destination[:contact_email]
        expect(group1.contact_tel).to eq destination[:contact_tel]
        expect(group1.contact_fax).to eq destination[:contact_fax]
        expect(group1.contact_link_url).to eq destination[:contact_link_url]
        expect(group1.contact_link_name).to eq destination[:contact_link_name]

        # check page
        page1.reload
        expect(page1.group_ids).to eq [ group1.id ]
        expect(page1.contact_group_id).to eq group1.id
        expect(page1.contact_email).to eq group1.contact_email
        expect(page1.contact_tel).to eq group1.contact_tel
        expect(page1.contact_fax).to eq group1.contact_fax
        expect(page1.contact_link_url).to eq group1.contact_link_url
        expect(page1.contact_link_name).to eq group1.contact_link_name

        page2.reload
        expect(page2.group_ids).to eq [ group1.id ]
        expect(page2.contact_group_id).to eq group1.id
        expect(page2.contact_email).to be_blank
        expect(page2.contact_tel).to be_blank
        expect(page2.contact_fax).to be_blank
        expect(page2.contact_link_url).to be_blank
        expect(page2.contact_link_name).to be_blank

        page3.reload
        expect(page3.group_ids).to eq [ group1.id ]
        expect(page3.contact_group_id).to eq group1.id
        expect(page3.contact_email).not_to eq group1.contact_email
        expect(page3.contact_tel).not_to eq group1.contact_tel
        expect(page3.contact_fax).not_to eq group1.contact_fax
        expect(page3.contact_link_url).not_to eq group1.contact_link_url
        expect(page3.contact_link_name).not_to eq group1.contact_link_name
      end
    end

    context "empty to non-empty" do
      let(:group_attributes) do
        {
          contact_email: "",
          contact_tel: "",
          contact_fax: "",
          contact_link_url: "",
          contact_link_name: ""
        }
      end
      let!(:group1) { create(:revision_new_group, group_attributes) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination) do
        {
          name: group1.name,
          order: "",
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id,
          ldap_dn: ""
        }
      end
      let!(:changeset) do
        create(
          :move_changeset, revision_id: revision.id, source: group1, destinations: [ destination.stringify_keys ]
        )
      end
      # group1 と同じ情報が連絡先にセットされているページ
      let!(:page1) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: group1.contact_email,
          contact_tel: group1.contact_tel,
          contact_fax: group1.contact_fax,
          contact_link_url: group1.contact_link_url,
          contact_link_name: group1.contact_link_name
        )
      end
      # 連絡先に異なる情報がセットされているページ
      let!(:page2) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id
        )
      end

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        group1.reload
        expect(group1.contact_email).to eq destination[:contact_email]
        expect(group1.contact_tel).to eq destination[:contact_tel]
        expect(group1.contact_fax).to eq destination[:contact_fax]
        expect(group1.contact_link_url).to eq destination[:contact_link_url]
        expect(group1.contact_link_name).to eq destination[:contact_link_name]

        # check page
        page1.reload
        expect(page1.group_ids).to eq [ group1.id ]
        expect(page1.contact_group_id).to eq group1.id
        expect(page1.contact_email).to eq group1.contact_email
        expect(page1.contact_tel).to eq group1.contact_tel
        expect(page1.contact_fax).to eq group1.contact_fax
        expect(page1.contact_link_url).to eq group1.contact_link_url
        expect(page1.contact_link_name).to eq group1.contact_link_name

        page2.reload
        expect(page2.group_ids).to eq [ group1.id ]
        expect(page2.contact_group_id).to eq group1.id
        expect(page2.contact_email).not_to eq group1.contact_email
        expect(page2.contact_tel).not_to eq group1.contact_tel
        expect(page2.contact_fax).not_to eq group1.contact_fax
        expect(page2.contact_link_url).not_to eq group1.contact_link_url
        expect(page2.contact_link_name).not_to eq group1.contact_link_name
      end
    end
  end

  context 'with forced_overwrite' do
    let(:job_opts) { { 'newly_created_group_to_site' => 'add', 'forced_overwrite' => true } }

    context "non-empty to non-empty" do
      let(:group_attributes) do
        {
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id
        }
      end
      let!(:group1) { create(:revision_new_group, group_attributes) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination) do
        {
          name: group1.name,
          order: "",
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id,
          ldap_dn: ""
        }
      end
      let!(:changeset) do
        create(
          :move_changeset, revision_id: revision.id, source: group1, destinations: [ destination.stringify_keys ]
        )
      end
      # group1 と同じ情報が連絡先にセットされているページ
      let!(:page1) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: group1.contact_email,
          contact_tel: group1.contact_tel,
          contact_fax: group1.contact_fax,
          contact_link_url: group1.contact_link_url,
          contact_link_name: group1.contact_link_name
        )
      end
      # 連絡先が空のページ
      let!(:page2) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: "",
          contact_tel: "",
          contact_fax: "",
          contact_link_url: "",
          contact_link_name: ""
        )
      end
      # 連絡先に異なる情報がセットされているページ
      let!(:page3) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id
        )
      end

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        group1.reload
        expect(group1.contact_email).to eq destination[:contact_email]
        expect(group1.contact_tel).to eq destination[:contact_tel]
        expect(group1.contact_fax).to eq destination[:contact_fax]
        expect(group1.contact_link_url).to eq destination[:contact_link_url]
        expect(group1.contact_link_name).to eq destination[:contact_link_name]

        # check page
        page1.reload
        expect(page1.group_ids).to eq [ group1.id ]
        expect(page1.contact_group_id).to eq group1.id
        expect(page1.contact_email).to eq group1.contact_email
        expect(page1.contact_tel).to eq group1.contact_tel
        expect(page1.contact_fax).to eq group1.contact_fax
        expect(page1.contact_link_url).to eq group1.contact_link_url
        expect(page1.contact_link_name).to eq group1.contact_link_name

        page2.reload
        expect(page2.group_ids).to eq [ group1.id ]
        expect(page2.contact_group_id).to eq group1.id
        expect(page2.contact_email).to eq group1.contact_email
        expect(page2.contact_tel).to eq group1.contact_tel
        expect(page2.contact_fax).to eq group1.contact_fax
        expect(page2.contact_link_url).to eq group1.contact_link_url
        expect(page2.contact_link_name).to eq group1.contact_link_name

        page3.reload
        expect(page3.group_ids).to eq [ group1.id ]
        expect(page3.contact_group_id).to eq group1.id
        expect(page3.contact_email).to eq group1.contact_email
        expect(page3.contact_tel).to eq group1.contact_tel
        expect(page3.contact_fax).to eq group1.contact_fax
        expect(page3.contact_link_url).to eq group1.contact_link_url
        expect(page3.contact_link_name).to eq group1.contact_link_name
      end
    end

    context "empty to non-empty" do
      let(:group_attributes) do
        {
          contact_email: "",
          contact_tel: "",
          contact_fax: "",
          contact_link_url: "",
          contact_link_name: ""
        }
      end
      let!(:group1) { create(:revision_new_group, group_attributes) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination) do
        {
          name: group1.name,
          order: "",
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id,
          ldap_dn: ""
        }
      end
      let!(:changeset) do
        create(
          :move_changeset, revision_id: revision.id, source: group1, destinations: [ destination.stringify_keys ]
        )
      end
      # group1 と同じ情報が連絡先にセットされているページ
      let!(:page1) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: group1.contact_email,
          contact_tel: group1.contact_tel,
          contact_fax: group1.contact_fax,
          contact_link_url: group1.contact_link_url,
          contact_link_name: group1.contact_link_name
        )
      end
      # 連絡先に異なる情報がセットされているページ
      let!(:page2) do
        create(
          :revisoin_page, cur_site: site, group: group1, filename: nil,
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: unique_url,
          contact_link_name: unique_id
        )
      end

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        group1.reload
        expect(group1.contact_email).to eq destination[:contact_email]
        expect(group1.contact_tel).to eq destination[:contact_tel]
        expect(group1.contact_fax).to eq destination[:contact_fax]
        expect(group1.contact_link_url).to eq destination[:contact_link_url]
        expect(group1.contact_link_name).to eq destination[:contact_link_name]

        # check page
        page1.reload
        expect(page1.group_ids).to eq [ group1.id ]
        expect(page1.contact_group_id).to eq group1.id
        expect(page1.contact_email).to eq group1.contact_email
        expect(page1.contact_tel).to eq group1.contact_tel
        expect(page1.contact_fax).to eq group1.contact_fax
        expect(page1.contact_link_url).to eq group1.contact_link_url
        expect(page1.contact_link_name).to eq group1.contact_link_name

        page2.reload
        expect(page2.group_ids).to eq [ group1.id ]
        expect(page2.contact_group_id).to eq group1.id
        expect(page2.contact_email).to eq group1.contact_email
        expect(page2.contact_tel).to eq group1.contact_tel
        expect(page2.contact_fax).to eq group1.contact_fax
        expect(page2.contact_link_url).to eq group1.contact_link_url
        expect(page2.contact_link_name).to eq group1.contact_link_name
      end
    end
  end
end
