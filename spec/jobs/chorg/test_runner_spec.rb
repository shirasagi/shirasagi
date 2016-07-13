require 'spec_helper'

describe Chorg::TestRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }

  context "with add" do
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:add_changeset, revision_id: revision.id) }

    it do
      expect(revision).not_to be_nil
      expect(changeset).not_to be_nil
      expect { described_class.bind(site_id: site).perform_now(revision.name, 1) }.not_to raise_error
      expect(Cms::Group.where(name: changeset.destinations.first["name"]).first).to be_nil
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
        # check for not changed
        expect { described_class.bind(site_id: site).perform_now(revision.name, 1) }.not_to raise_error
        expect(Cms::Group.where(id: group.id).first).not_to be_nil
        expect(Cms::Group.where(id: group.id).first.name).to eq changeset.sources.first["name"]

        page.reload
        expect(page.group_ids).to eq [ group.id ]
        expect(page.contact_group_id).to eq group.id
        expect(page.contact_email).to eq group.contact_email
        expect(page.contact_tel).to eq group.contact_tel
        expect(page.contact_fax).to eq group.contact_fax
      end
    end
  end

  context "with unify" do
    let(:group1) { create(:revision_new_group) }
    let(:group2) { create(:revision_new_group) }
    let(:user1) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
    let(:user2) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:unify_changeset, revision_id: revision.id, sources: [group1, group2]) }

    context "with Article::Page" do
      let(:page) { create(:revisoin_page, cur_site: site, group: group1) }

      it do
        # ensure create models
        expect(user1).not_to be_nil
        expect(user2).not_to be_nil
        expect(revision).not_to be_nil
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil

        # check for not changed
        expect { described_class.bind(site_id: site, user_id: user1).perform_now(revision.name, 1) }.not_to raise_error
        expect(Cms::Group.where(id: group1.id).first).not_to be_nil
        expect(Cms::Group.where(id: group1.id).first.name).to eq group1.name
        expect(Cms::Group.where(id: group2.id).first).not_to be_nil
        expect(Cms::Group.where(id: group2.id).first.name).to eq group2.name

        page.reload
        expect(page.group_ids).to eq [ group1.id ]
        expect(page.contact_group_id).to eq group1.id
        expect(page.contact_email).to eq group1.contact_email
        expect(page.contact_tel).to eq group1.contact_tel
        expect(page.contact_fax).to eq group1.contact_fax

        user1.reload
        expect(user1.group_ids).to eq [group1.id]
        user2.reload
        expect(user2.group_ids).to eq [group2.id]
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
      # change group.
      expect { described_class.bind(site_id: site).perform_now(revision.name, 1) }.not_to raise_error
      # check for not changed
      expect(Cms::Group.where(id: group.id).first).not_to be_nil
    end
  end
end
