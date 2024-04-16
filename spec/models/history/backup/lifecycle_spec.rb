require 'spec_helper'

describe History::Backup, type: :model, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:item) { Timecop.freeze(now - 13.days) { create :cms_page } }

  it do
    item.backups.to_a.tap do |backups|
      expect(backups.count).to eq 1
      backups[0].tap do |backup|
        expect(backup.state).to eq "current"
        expect(backup.updated).to eq now - 13.days
        expect(backup.created).to eq now - 13.days
      end
    end

    Timecop.freeze(now - 11.days) do
      item.name = unique_id
      item.save!
    end

    item.backups.to_a.tap do |backups|
      expect(backups.count).to eq 2
      backups[0].tap do |backup|
        expect(backup.state).to eq "current"
        expect(backup.updated).to eq now - 11.days
        expect(backup.created).to eq now - 11.days
      end
      backups[1].tap do |backup|
        # timestamps should be kept
        expect(backup.state).to eq "before"
        expect(backup.updated).to eq now - 13.days
        expect(backup.created).to eq now - 13.days
      end
    end

    Timecop.freeze(now - 5.days) do
      item.name = unique_id
      item.save!
    end

    item.backups.to_a.tap do |backups|
      expect(backups.count).to eq 3
      backups[0].tap do |backup|
        expect(backup.state).to eq "current"
        expect(backup.updated).to eq now - 5.days
        expect(backup.created).to eq now - 5.days
      end
      backups[1].tap do |backup|
        # timestamps should be kept
        expect(backup.state).to eq "before"
        expect(backup.updated).to eq now - 11.days
        expect(backup.created).to eq now - 11.days
      end
      backups[2].tap do |backup|
        # timestamps should be kept
        expect(backup.state).to be_blank
        expect(backup.updated).to eq now - 13.days
        expect(backup.created).to eq now - 13.days
      end
    end

    History::Backup.max_age.times do |i|
      Timecop.freeze(now - 3.days + i.hours) do
        item.name = unique_id
        item.save!
      end
    end

    item.backups.to_a.tap do |backups|
      expect(backups.count).to eq History::Backup.max_age
    end
  end
end
