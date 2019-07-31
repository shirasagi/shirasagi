require 'spec_helper'
require 'fileutils'

RSpec.describe SS::Migration, type: :model, dbscope: :example, tmpdir: true do
  def mkdir(dirname)
    FileUtils.mkdir_p dirname
  end

  def touch(filepath)
    File.open(filepath, 'w') {}
    filepath
  end

  describe 'DIR constant' do
    it { expect(described_class::DIR.to_s).to match(/.*\/lib\/migrations$/) }
  end

  describe '.filepaths' do
    before do
      mkdir "#{tmpdir}/migrations/mod1"
      mkdir "#{tmpdir}/migrations/mod2"
      touch "#{tmpdir}/migrations/mod2/20150324000000_a.rb"
      touch "#{tmpdir}/migrations/mod1/20150324000001_a.rb"
      touch "#{tmpdir}/migrations/mod1/20150324000002_a.rb"
      touch "#{tmpdir}/migrations/mod2/20150324000003_a.rb"
      # ref.
      #   http://docs.ruby-lang.org/ja/2.2.0/method/Module/i/remove_const.html
      #   http://docs.ruby-lang.org/ja/2.2.0/class/Module.html#I_CLASS_EVAL
      SS::Migration.class_eval { remove_const :DIR }
      SS::Migration::DIR = Rails.root.join "#{tmpdir}/migrations"
    end

    it do
      expect(described_class.filepaths).to match(
        [
          /.*\/mod2\/20150324000000_a\.rb$/,
          /.*\/mod1\/20150324000001_a\.rb$/,
          /.*\/mod1\/20150324000002_a\.rb$/,
          /.*\/mod2\/20150324000003_a\.rb$/,
        ]
      )
    end
  end

  describe '.latest_version' do
    subject { described_class.latest_version }

    context 'no version exists' do
      it { is_expected.to eq '00000000000000' }
    end

    context '1 version exists' do
      before { create :ss_migration, version: '20150324000001' }
      it { is_expected.to eq '20150324000001' }
    end

    context '2 versions exist' do
      before do
        create :ss_migration, version: '20150324000000'
        create :ss_migration, version: '20150324000001'
      end

      it { is_expected.to eq '20150324000001' }
    end

    context '2 reversed ordered versions exist' do
      before do
        create :ss_migration, version: '20150324000001'
        create :ss_migration, version: '20150324000000'
      end

      it { is_expected.to eq '20150324000001' }
    end
  end

  describe '.take_timestamp' do
    subject { described_class.take_timestamp '/a/b/20150330000000_c_d.rb' }
    it { is_expected.to eq '20150330000000' }
  end

  describe '.filepaths_to_apply' do
    before do
      mkdir "#{tmpdir}/migrations/mod1"
      touch "#{tmpdir}/migrations/mod1/20150330000000_a.rb"
      touch "#{tmpdir}/migrations/mod1/20150330000001_a.rb"
      SS::Migration.class_eval { remove_const :DIR }
      SS::Migration::DIR = Rails.root.join "#{tmpdir}/migrations"
    end

    subject { described_class.filepaths_to_apply }

    context 'when no migration is applied' do
      it do
        is_expected.to match [
          /.*\/20150330000000_a.rb$/,
          /.*\/20150330000001_a.rb$/,
        ]
      end
    end

    context 'after 1st migration is applied' do
      before { create :ss_migration, version: '20150330000000' }
      it { is_expected.to match [/.*\/20150330000001_a.rb$/] }
    end

    context 'when no migration to apply exists' do
      before do
        create :ss_migration, version: '20150330000000'
        create :ss_migration, version: '20150330000001'
      end

      it { is_expected.to eq [] }
    end
  end
end
