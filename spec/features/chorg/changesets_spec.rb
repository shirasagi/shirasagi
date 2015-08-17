require 'spec_helper'

describe "chorg_changesets", dbscope: :example do
  let(:site) { cms_site }
  let(:revision) { create(:revision, site_id: site.id) }
  let(:index_path) { chorg_changesets_changesets_path site.id, revision.id, "add" }
  let(:revision_show_path) { chorg_revisions_revision_path site.id, revision.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  it "#index" do
    login_cms_user
    visit index_path
    expect(status_code).to eq 200
    # redirected to "chorg/revisions#show"
    expect(current_path).to eq revision_show_path
  end

  describe "#show" do
    context "with add" do
      let(:changeset) { create(:add_changeset, revision_id: revision.id) }
      let(:add_show_path) { chorg_changesets_changeset_path site.id, revision.id, "add", changeset.id }

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil

        login_cms_user
        visit add_show_path
        expect(status_code).to eq 200
        expect(page).to have_selector("div.addon-view dl.see")
      end

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil
        # login
        login_cms_user
        %w(add move unify division delete).each do |type|
          path = chorg_changesets_changeset_path(site.id, revision.id, type, changeset.id)
          next if add_show_path == path
          visit path
          expect(status_code).to eq 404
        end
      end
    end

    context "with move" do
      let(:group) { create(:revision_new_group) }
      let(:changeset) { create(:move_changeset, revision_id: revision.id, source: group) }
      let(:move_show_path) { chorg_changesets_changeset_path site.id, revision.id, "move", changeset.id }

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil

        login_cms_user
        visit move_show_path
        expect(status_code).to eq 200
        expect(page).to have_selector("div.addon-view dl.see")
      end

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil
        # login
        login_cms_user
        %w(add move unify division delete).each do |type|
          path = chorg_changesets_changeset_path(site.id, revision.id, type, changeset.id)
          next if move_show_path == path
          visit path
          expect(status_code).to eq 404
        end
      end
    end

    context "with unify" do
      let(:group1) { create(:revision_new_group) }
      let(:group2) { create(:revision_new_group) }
      let(:changeset) { create(:unify_changeset, revision_id: revision.id, sources: [group1, group2]) }
      let(:unify_show_path) { chorg_changesets_changeset_path site.id, revision.id, "unify", changeset.id }

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil

        login_cms_user
        visit unify_show_path
        expect(status_code).to eq 200
        expect(page).to have_selector("div.addon-view dl.see")
      end

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil
        # login
        login_cms_user
        %w(add move unify division delete).each do |type|
          path = chorg_changesets_changeset_path(site.id, revision.id, type, changeset.id)
          next if unify_show_path == path
          visit path
          expect(status_code).to eq 404
        end
      end
    end

    context "with division" do
      let(:group0) { create(:revision_new_group) }
      let(:group1) { build(:revision_new_group) }
      let(:group2) { build(:revision_new_group) }
      let(:changeset) do
        create(:division_changeset, revision_id: revision.id, source: group0, destinations: [group1, group2])
      end
      let(:division_show_path) { chorg_changesets_changeset_path site.id, revision.id, "division", changeset.id }

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil

        login_cms_user
        visit division_show_path
        expect(status_code).to eq 200
        expect(page).to have_selector("div.addon-view dl.see")
      end

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil
        # login
        login_cms_user
        %w(add move unify division delete).each do |type|
          path = chorg_changesets_changeset_path(site.id, revision.id, type, changeset.id)
          next if division_show_path == path
          visit path
          expect(status_code).to eq 404
        end
      end
    end

    context "with delete" do
      let(:group) { create(:revision_new_group) }
      let(:changeset) { create(:delete_changeset, revision_id: revision.id, source: group) }
      let(:delete_show_path) { chorg_changesets_changeset_path site.id, revision.id, "delete", changeset.id }

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil

        login_cms_user
        visit delete_show_path
        expect(status_code).to eq 200
        expect(page).to have_selector("div.addon-view dl.see")
      end

      it do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil
        # login
        login_cms_user
        %w(add move unify division delete).each do |type|
          path = chorg_changesets_changeset_path(site.id, revision.id, type, changeset.id)
          next if delete_show_path == path
          visit path
          expect(status_code).to eq 404
        end
      end
    end
  end
end
