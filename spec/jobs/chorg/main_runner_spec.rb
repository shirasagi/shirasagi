require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }

  context "with add" do
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:add_changeset, revision_id: revision.id) }

    it do
      expect(changeset).not_to be_nil
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, 1) }.not_to raise_error

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
        expect { job.perform_now(revision.name, 1) }.not_to raise_error

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
        expect(task.entity_logs[1]['changes']).to include('contact_tel', 'contact_fax', 'contact_email')
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
          expect { job.perform_now(revision.name, 1) }.not_to raise_error

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
          expect(task.entity_logs[0]['changes']).to include('name')
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
        expect { job.perform_now(revision.name, 1) }.not_to raise_error

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
        expect(task.entity_logs[0]['changes']).to include('name')
        expect(task.entity_logs[1]['model']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq '1'
        expect(task.entity_logs[1]['changes']).to include('contact_tel', 'contact_fax', 'contact_email')
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
        expect { job.perform_now(revision.name, 1) }.not_to raise_error

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
        expect(task.entity_logs[4]['changes']).to include('contact_tel', 'contact_fax', 'contact_email')

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
        expect { job.perform_now(revision.name, 1) }.not_to raise_error

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
        expect(task.entity_logs[0]['changes']).not_to be_nil
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
        expect { job.perform_now(revision.name, 1) }.not_to raise_error

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
        expect(task.entity_logs[5]['changes']).to include('contact_email', 'contact_group_id')

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
        expect { job.perform_now(revision.name, 1) }.not_to raise_error

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
        expect(task.entity_logs[3]['changes']).not_to be_nil
      end
    end
  end

  context "with delete" do
    let(:group) { create(:revision_new_group) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:delete_changeset, revision_id: revision.id, source: group) }

    it do
      # ensure create models
      expect(changeset).not_to be_nil
      # execute
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, 1) }.not_to raise_error

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Cms::Group.where(id: group.id).first).to be_nil

      task.reload
      expect(task.state).to eq 'stop'
      expect(task.entity_logs.count).to eq 1
      expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
      expect(task.entity_logs[0]['id']).to eq group.id.to_s
      expect(task.entity_logs[0]['deletes']).to include('name', 'contact_email')
    end
  end
end
