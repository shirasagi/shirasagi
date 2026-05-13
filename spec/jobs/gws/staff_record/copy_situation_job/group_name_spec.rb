require 'spec_helper'

describe Gws::StaffRecord::CopySituationJob, dbscope: :example do
  let!(:site) { create(:gws_group) }
  let!(:user) { create(:gws_user, group_ids: [ site.id ]) }
  let!(:year) { create(:gws_staff_record_year, cur_site: site, cur_user: user) }

  context "duplicated trailing group name" do
    # normal case
    let!(:name1) { unique_id }
    let!(:name2) { unique_id }
    let!(:name3) { unique_id }
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{name1}") }
    let!(:group2) { create(:gws_group, name: "#{site.name}/#{name1}/#{name2}") }
    let!(:group3) { create(:gws_group, name: "#{site.name}/#{name1}/#{name3}") }

    # duplicated trailing name
    let!(:name4) { unique_id }
    let!(:name5) { unique_id }
    let!(:name6) { unique_id }
    let!(:group4) { create(:gws_group, name: "#{site.name}/#{name4}") }
    let!(:group5) { create(:gws_group, name: "#{site.name}/#{name4}/#{name5}") }
    let!(:group6) { create(:gws_group, name: "#{site.name}/#{name6}") }
    let!(:group7) { create(:gws_group, name: "#{site.name}/#{name6}/#{name5}") }

    let!(:duplicated_group5) { I18n.t("gws/staff_record.formatted_group_name", name: name5, parent: name4) }
    let!(:duplicated_group7) { I18n.t("gws/staff_record.formatted_group_name", name: name5, parent: name6) }

    it do
      described_class.bind(site_id: site).perform_now(year.id.to_s)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
      expect(Gws::StaffRecord::Group.count).to eq 8

      # normal case
      Gws::StaffRecord::Group.find_by(name: site.trailing_name).tap do |g|
        expect(g.name).to eq site.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: group1.trailing_name).tap do |g|
        expect(g.name).to eq group1.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: group2.trailing_name).tap do |g|
        expect(g.name).to eq group2.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: group3.trailing_name).tap do |g|
        expect(g.name).to eq group3.trailing_name
      end

      # duplicated trailing name
      Gws::StaffRecord::Group.find_by(name: group4.trailing_name).tap do |g|
        expect(g.name).to eq group4.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group5).tap do |g|
        expect(g.name).to eq duplicated_group5
      end
      Gws::StaffRecord::Group.find_by(name: group6.trailing_name).tap do |g|
        expect(g.name).to eq group6.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group7).tap do |g|
        expect(g.name).to eq duplicated_group7
      end
    end
  end

  context "duplicated 2 depth group name" do
    # normal case
    let!(:name1) { unique_id }
    let!(:name2) { unique_id }
    let!(:name3) { unique_id }
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{name1}") }
    let!(:group2) { create(:gws_group, name: "#{site.name}/#{name1}/#{name2}") }
    let!(:group3) { create(:gws_group, name: "#{site.name}/#{name1}/#{name3}") }

    # duplicated trailing name
    let!(:name4) { unique_id }
    let!(:name5) { unique_id }
    let!(:name6) { unique_id }
    let!(:name7) { unique_id }
    let!(:name8) { unique_id }
    let!(:name9) { unique_id }
    let!(:group4) { create(:gws_group, name: "#{site.name}/#{name4}") }
    let!(:group5) { create(:gws_group, name: "#{site.name}/#{name4}/#{name5}") }
    let!(:group6) { create(:gws_group, name: "#{site.name}/#{name4}/#{name5}/#{name6}") }
    let!(:group7) { create(:gws_group, name: "#{site.name}/#{name7}") }
    let!(:group8) { create(:gws_group, name: "#{site.name}/#{name7}/#{name5}") }
    let!(:group9) { create(:gws_group, name: "#{site.name}/#{name7}/#{name5}/#{name6}") }

    let!(:duplicated_group5) { I18n.t("gws/staff_record.formatted_group_name", name: name5, parent: name4) }
    let!(:duplicated_group6) { I18n.t("gws/staff_record.formatted_group_name", name: name6, parent: name5) }
    let!(:duplicated_group8) { I18n.t("gws/staff_record.formatted_group_name", name: name5, parent: name7) }
    let!(:duplicated_group9) { I18n.t("gws/staff_record.formatted_group_name", name: name6, parent: name5) + ".2" }

    it do
      described_class.bind(site_id: site).perform_now(year.id.to_s)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
      expect(Gws::StaffRecord::Group.count).to eq 10

      # normal case
      Gws::StaffRecord::Group.find_by(name: site.trailing_name).tap do |g|
        expect(g.name).to eq site.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: group1.trailing_name).tap do |g|
        expect(g.name).to eq group1.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: group2.trailing_name).tap do |g|
        expect(g.name).to eq group2.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: group3.trailing_name).tap do |g|
        expect(g.name).to eq group3.trailing_name
      end

      # duplicated trailing name
      Gws::StaffRecord::Group.find_by(name: group4.trailing_name).tap do |g|
        expect(g.name).to eq group4.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group5).tap do |g|
        expect(g.name).to eq duplicated_group5
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group6).tap do |g|
        expect(g.name).to eq duplicated_group6
      end
      Gws::StaffRecord::Group.find_by(name: group7.trailing_name).tap do |g|
        expect(g.name).to eq group7.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group8).tap do |g|
        expect(g.name).to eq duplicated_group8
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group9).tap do |g|
        expect(g.name).to eq duplicated_group9
      end
    end
  end

  context "duplicated 2 depth group name" do
    # duplicated trailing name
    let!(:name1) { unique_id }
    let!(:name2) { unique_id }
    let!(:name3) { unique_id }
    let!(:name4) { unique_id }
    let!(:name5) { unique_id }
    let!(:name6) { unique_id }
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{name1}") }
    let!(:group2) { create(:gws_group, name: "#{site.name}/#{name1}/#{name2}") }
    let!(:group3) { create(:gws_group, name: "#{site.name}/#{name1}/#{name2}/#{name3}") }
    let!(:group4) { create(:gws_group, name: "#{site.name}/#{name2}") }
    let!(:group5) { create(:gws_group, name: "#{site.name}/#{name2}/#{name3}") }
    let!(:group6) { create(:gws_group, name: "#{site.name}/#{name3}") }
    let!(:group7) { create(:gws_group, name: "#{site.name}/#{name4}") }
    let!(:group8) { create(:gws_group, name: "#{site.name}/#{name4}/#{name2}") }
    let!(:group9) { create(:gws_group, name: "#{site.name}/#{name4}/#{name2}/#{name3}") }

    let!(:duplicated_group2) { I18n.t("gws/staff_record.formatted_group_name", name: name2, parent: name1) }
    let!(:duplicated_group3) { I18n.t("gws/staff_record.formatted_group_name", name: name3, parent: name2) }
    let!(:duplicated_group4) { I18n.t("gws/staff_record.formatted_group_name", name: name2, parent: site.name) }
    let!(:duplicated_group5) { I18n.t("gws/staff_record.formatted_group_name", name: name3, parent: name2) + ".2" }
    let!(:duplicated_group6) { I18n.t("gws/staff_record.formatted_group_name", name: name3, parent: site.name) }
    let!(:duplicated_group8) { I18n.t("gws/staff_record.formatted_group_name", name: name2, parent: name4) }
    let!(:duplicated_group9) { I18n.t("gws/staff_record.formatted_group_name", name: name3, parent: name2) + ".3" }

    it do
      described_class.bind(site_id: site).perform_now(year.id.to_s)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
      expect(Gws::StaffRecord::Group.count).to eq 10

      # duplicated trailing name
      Gws::StaffRecord::Group.find_by(name: group1.trailing_name).tap do |g|
        expect(g.name).to eq group1.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group2).tap do |g|
        expect(g.name).to eq duplicated_group2
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group3).tap do |g|
        expect(g.name).to eq duplicated_group3
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group4).tap do |g|
        expect(g.name).to eq duplicated_group4
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group5).tap do |g|
        expect(g.name).to eq duplicated_group5
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group6).tap do |g|
        expect(g.name).to eq duplicated_group6
      end
      Gws::StaffRecord::Group.find_by(name: group7.trailing_name).tap do |g|
        expect(g.name).to eq group7.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group8).tap do |g|
        expect(g.name).to eq duplicated_group8
      end
      Gws::StaffRecord::Group.find_by(name: duplicated_group9).tap do |g|
        expect(g.name).to eq duplicated_group9
      end
    end
  end
end
