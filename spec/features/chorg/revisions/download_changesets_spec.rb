require 'spec_helper'

describe "chorg_download_revision", type: :feature, dbscope: :example do
  let!(:site) { cms_site }

  let!(:group0) { create(:revision_new_group) }
  let!(:group1) { create(:revision_new_group) }
  let!(:group2) { create(:revision_new_group) }
  let!(:group3) { create(:revision_new_group) }
  let!(:group4) { create(:revision_new_group) }
  let!(:group5) { create(:revision_new_group) }
  let!(:group6) { create(:revision_new_group) }

  let!(:revision) { create(:revision, site_id: site.id) }

  let!(:changeset0) { create(:add_changeset, revision_id: revision.id) }
  let!(:changeset1) { create(:move_changeset, revision_id: revision.id, source: group0) }
  let!(:changeset2) { create(:unify_changeset, revision_id: revision.id, sources: [group1, group2]) }
  let!(:changeset3) do
    create(:division_changeset, revision_id: revision.id, source: group3, destination: [group4, group5])
  end
  let!(:changeset4) { create(:delete_changeset, revision_id: revision.id, source: group6) }
  let!(:show_path) { chorg_revision_path site: site.id, id: revision.id }

  context "revision download in show path" do
    before { login_cms_user }

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path

      first(".chorg-revisions a", text: I18n.t('ss.links.download')).click
      expect(page.response_headers['Content-Type']).to eq("text/csv; charset=utf-8")

      csv_source = ::SS::ChunkReader.new(page.html).to_a.join
      csv_source.force_encoding("UTF-8")
      csv_source = csv_source[1..-1]

      changesets = {}
      table = CSV.parse(csv_source, headers: true)
      table.each do |row|
        type = row[I18n.t("chorg.import.changeset.type")]
        changesets[type] ||= []
        changesets[type] << row
      end

      # add
      add_changesets = changesets[I18n.t("chorg.options.changeset_type.add")]
      expect(add_changesets).not_to be nil
      expect(add_changesets.size).to eq 1

      sources = add_changesets.map { |changeset| changeset[I18n.t("chorg.import.changeset.source")] }.uniq
      destinations = add_changesets.map do |changeset|
        changeset[I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: 1)]
      end
      destinations.uniq!

      expect(sources).to match_array [nil]
      expect(destinations).to match_array(changeset0.destinations.map { |item| item["name"] })

      # move
      move_changesets = changesets[I18n.t("chorg.options.changeset_type.move")]
      expect(move_changesets).not_to be nil
      expect(move_changesets.size).to eq 1

      sources = move_changesets.map { |changeset| changeset[I18n.t("chorg.import.changeset.source")] }.uniq
      destinations = move_changesets.map do |changeset|
        changeset[I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: 1)]
      end
      destinations.uniq!

      expect(sources).to match_array(changeset1.sources.map { |item| item["name"] })
      expect(destinations).to match_array(changeset1.destinations.map { |item| item["name"] })

      # unify
      unify_changesets = changesets[I18n.t("chorg.options.changeset_type.unify")]
      expect(unify_changesets).not_to be nil
      expect(unify_changesets.size).to eq 1

      sources = unify_changesets.map { |changeset| changeset[I18n.t("chorg.import.changeset.source")] }.uniq
      destinations = unify_changesets.map do |changeset|
        changeset[I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: 1)]
      end
      destinations.uniq!

      expect(sources).to match_array([ changeset2.sources.map { |item| item["name"] }.join("\n") ])
      expect(destinations).to match_array(changeset2.destinations.map { |item| item["name"] })

      # division
      division_changesets = changesets[I18n.t("chorg.options.changeset_type.division")]
      expect(division_changesets).not_to be nil
      expect(division_changesets.size).to eq 1

      sources = division_changesets.map { |changeset| changeset[I18n.t("chorg.import.changeset.source")] }.uniq
      destinations = division_changesets.map do |changeset|
        changeset[I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: 1)]
      end
      destinations += division_changesets.map do |changeset|
        changeset[I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: 2)]
      end
      destinations.uniq!

      expect(sources).to match_array(changeset3.sources.map { |item| item["name"] })
      expect(destinations).to match_array(changeset3.destinations.map { |item| item["name"] })

      # delete
      delete_changesets = changesets[I18n.t("chorg.options.changeset_type.delete")]
      expect(delete_changesets).not_to be nil
      expect(delete_changesets.size).to eq 1

      sources = delete_changesets.map { |changeset| changeset[I18n.t("chorg.import.changeset.source")] }.uniq
      destinations = delete_changesets.map do |changeset|
        changeset[I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: 1)]
      end
      destinations.uniq!

      expect(sources).to match_array(changeset4.sources.map { |item| item["name"] })
      expect(destinations).to match_array [nil]
    end
  end
end
