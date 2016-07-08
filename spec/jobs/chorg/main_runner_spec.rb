require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }

  context "with add" do
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:add_changeset, revision_id: revision.id) }

    it do
      expect(changeset).not_to be_nil
      expect { described_class.bind(site_id: site).perform_now(revision.name, 1) }.not_to raise_error
      expect(Cms::Group.where(name: changeset.destinations.first["name"]).first).not_to be_nil
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
        expect { described_class.bind(site_id: site).perform_now(revision.name, 1) }.not_to raise_error
        expect(Cms::Group.where(name: group.name).first).to be_nil
        expect(Cms::Group.where(id: group.id).first.name).to eq changeset.destinations.first["name"]
        expect(Cms::Group.where(id: group.id).first.contact_email).to eq changeset.destinations.first["contact_email"]
        expect(Cms::Group.where(id: group.id).first.contact_tel).to eq changeset.destinations.first["contact_tel"]
        expect(Cms::Group.where(id: group.id).first.contact_fax).to eq changeset.destinations.first["contact_fax"]
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
          expect { described_class.bind(site_id: site).perform_now(revision.name, 1) }.not_to raise_error
          expect(Cms::Group.where(name: group.name).first).to be_nil
          expect(Cms::Group.where(id: group.id).first.name).to eq changeset.destinations.first["name"]
          # these attributes are expected not to be changed.
          expect(Cms::Group.where(id: group.id).first.contact_email).to eq group.contact_email
          expect(Cms::Group.where(id: group.id).first.contact_tel).to eq group.contact_tel
          expect(Cms::Group.where(id: group.id).first.contact_fax).to eq group.contact_fax
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
        expect { described_class.bind(site_id: site, user_id: user1).perform_now(revision.name, 1) }.not_to raise_error
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
        expect { described_class.bind(site_id: site, user_id: user1).perform_now(revision.name, 1) }.not_to raise_error
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

        user1.reload
        expect(user1.group_ids).to eq [new_group.id]
        user2.reload
        expect(user2.group_ids).to eq [new_group.id]
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
        expect(page).not_to be_nil
        expect(page.contact_email).to eq "foobar02@example.jp"
        # execute
        expect { described_class.bind(site_id: site, user_id: user1).perform_now(revision.name, 1) }.not_to raise_error
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

        user1.reload
        expect(user1.group_ids).to eq [new_group.id]
        user2.reload
        expect(user2.group_ids).to eq [new_group.id]
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
        expect { described_class.bind(site_id: site, user_id: user).perform_now(revision.name, 1) }.not_to raise_error
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

        user.reload
        expect(user.group_ids).to eq [ new_group1.id ]
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
        expect { described_class.bind(site_id: site, user_id: user).perform_now(revision.name, 1) }.not_to raise_error
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

        user.reload
        expect(user.group_ids).to eq [ new_group1.id ]
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
      expect { described_class.bind(site_id: site).perform_now(revision.name, 1) }.not_to raise_error
      expect(Cms::Group.where(id: group.id).first).to be_nil
    end
  end
end
