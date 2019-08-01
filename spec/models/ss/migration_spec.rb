require 'spec_helper'
require 'fileutils'
require "ss/migration/base"

RSpec.describe SS::Migration, type: :model, dbscope: :example, tmpdir: true do
  def mkdir(dirname)
    FileUtils.mkdir_p dirname
  end

  def migration_file(filepath, depend_on: nil)
    version, _name = described_class.parse_migration_filename(filepath)
    File.open(filepath, 'w') do |f|
      f.puts "class SS::Migration#{version}"
      f.puts "  include SS::Migration::Base"
      f.puts "  depends_on \"#{depend_on}\"" if depend_on.present?
      f.puts "  def change"
      f.puts "  end"
      f.puts "end"
    end

    filepath
  end

  describe 'DIR constant' do
    it { expect(described_class::DIR.to_s).to match(/.*\/lib\/migrations$/) }
  end

  context 'with migrations' do
    before do
      mkdir "#{tmpdir}/migrations/mod1"
      mkdir "#{tmpdir}/migrations/mod2"
      migration_file "#{tmpdir}/migrations/mod2/20150324000000_a.rb"
      migration_file "#{tmpdir}/migrations/mod1/20150324000001_a.rb", depend_on: "20150324000000"
      migration_file "#{tmpdir}/migrations/mod1/20150324000002_a.rb", depend_on: "20150324000001"
      migration_file "#{tmpdir}/migrations/mod2/20150324000002_b.rb"
      migration_file "#{tmpdir}/migrations/mod2/20150324000003_a.rb", depend_on: "20150324000002"
      # ref.
      #   http://docs.ruby-lang.org/ja/2.2.0/method/Module/i/remove_const.html
      #   http://docs.ruby-lang.org/ja/2.2.0/class/Module.html#I_CLASS_EVAL
      SS::Migration.class_eval { remove_const :DIR }
      SS::Migration::DIR = Rails.root.join "#{tmpdir}/migrations"
    end

    describe '.filepaths' do
      it do
        expect(described_class.filepaths).to match(
          [
            /.*\/mod2\/20150324000000_a\.rb$/,
            /.*\/mod1\/20150324000001_a\.rb$/,
            /.*\/mod1\/20150324000002_a\.rb$/,
            /.*\/mod2\/20150324000002_b\.rb$/,
            /.*\/mod2\/20150324000003_a\.rb$/,
          ]
        )
      end
    end

    describe '.migrate' do
      context "without VERSION env" do
        it do
          expect { described_class.migrate }.to output(include("Applied SS::Migration20150324000002")).to_stdout

          expect(described_class.all).to have(5).items
          expect(described_class.where(version: "20150324000000")).to be_present
          expect(described_class.where(version: "20150324000001")).to be_present
          expect(described_class.where(version: "20150324000002")).to be_present
          expect(described_class.where(version: "20150324000003")).to be_present
          expect(described_class.where(version: "20150324000004")).to be_blank
        end
      end

      context "with VERSION env" do
        it do
          with_env("VERSION" => "20150324000002") do
            expect { described_class.migrate }.to output(include("Applied SS::Migration20150324000002")).to_stdout

            expect(described_class.all).to have(4).items
            expect(described_class.where(version: "20150324000000")).to be_present
            expect(described_class.where(version: "20150324000001")).to be_present
            expect(described_class.where(version: "20150324000002")).to be_present
            expect(described_class.where(version: "20150324000003")).to be_blank
            expect(described_class.where(version: "20150324000004")).to be_blank
          end
        end
      end

      context "with CHECK_DEPENDENCY env" do
        it do
          with_env("CHECK_DEPENDENCY" => "1") do
            expect { described_class.migrate }.to output(include("Applied SS::Migration20150324000002")).to_stdout
            expect(described_class.all).to have(0).items
          end
        end
      end
    end

    describe '.up' do
      context "with dependent version" do
        before { create :ss_migration, version: '20150324000001' }

        it do
          with_env("VERSION" => "20150324000002") do
            expect { described_class.up }.to output(include("Applied SS::Migration20150324000002")).to_stdout

            expect(described_class.all).to have(3).items
            expect(described_class.where(version: "20150324000000")).to be_blank
            expect(described_class.where(version: "20150324000001")).to be_present
            expect(described_class.where(version: "20150324000002")).to be_present
            expect(described_class.where(version: "20150324000003")).to be_blank
            expect(described_class.where(version: "20150324000004")).to be_blank
          end
        end
      end

      context "with CHECK_DEPENDENCY env" do
        before { create :ss_migration, version: '20150324000001' }

        it do
          with_env("VERSION" => "20150324000002", "CHECK_DEPENDENCY" => "1") do
            expect { described_class.up }.to output(include("Applied SS::Migration20150324000002")).to_stdout

            expect(described_class.all).to have(1).items
            expect(described_class.where(version: "20150324000000")).to be_blank
            expect(described_class.where(version: "20150324000001")).to be_present
            expect(described_class.where(version: "20150324000002")).to be_blank
            expect(described_class.where(version: "20150324000003")).to be_blank
            expect(described_class.where(version: "20150324000004")).to be_blank
          end
        end
      end

      context "without dependent version" do
        it do
          with_env("VERSION" => "20150324000003") do
            expect { described_class.up }.to raise_error "Error SS::Migration20150324000003 is required 20150324000002"
            expect(described_class.all).to have(0).items
          end
        end
      end
    end

    describe '.status' do
      let(:outs) do
        [
          "#{"down".center(8)}  #{"20150324000000".ljust(14)}  a",
          "#{"up".center(8)}  #{"20150324000001".ljust(14)}  a",
          "#{"down".center(8)}  #{"20150324000002".ljust(14)}  a, b",
          "#{"down".center(8)}  #{"20150324000003".ljust(14)}  a",
          "#{"up".center(8)}  #{"20150324000004".ljust(14)}  ********** NO FILE **********"
        ]
      end

      before { create :ss_migration, version: '20150324000001' }
      before { create :ss_migration, version: '20150324000004' }

      it do
        expect { described_class.status }.to output(include(*outs)).to_stdout
      end
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
      migration_file "#{tmpdir}/migrations/mod1/20150330000000_a.rb"
      migration_file "#{tmpdir}/migrations/mod1/20150330000001_a.rb"
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
