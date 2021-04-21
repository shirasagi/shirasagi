require 'spec_helper'
require Rails.root.join('lib/generators/ss_migration/ss_migration_generator.rb')

describe SsMigrationGenerator, dbscope: :example do
  before do
    SS::Migration.class_eval { remove_const :DIR }
    SS::Migration::DIR = Rails.root.join "#{tmpdir}/lib/migrations"

    SsMigrationGenerator.class_eval { remove_const :SPEC_DIR }
    SsMigrationGenerator::SPEC_DIR = Rails.root.join "#{tmpdir}/spec/lib/migrations"
  end

  describe "help" do
    it do
      expect { described_class.start(%w(--help)) }.to output(include("rails generate ss_migration NAME [options]")).to_stdout
    end
  end

  describe "generate" do
    let(:now) { Time.zone.now.beginning_of_minute }
    let(:seq) { 0 }
    let(:name) { unique_id }
    let(:module_name) { unique_id }
    let(:basename) { "#{now.strftime("%Y%m%d")}#{seq.to_s.rjust(6, "0")}_#{name}" }

    before do
      Timecop.freeze(now) do
        expect { described_class.start(argv) }.to output(include(*outs)).to_stdout
      end
    end

    context "without module" do
      let(:argv) { [ name ] }
      let(:outs) { [ "lib/migrations/#{basename}" ] }

      it do
        expect(::File.exists?("#{tmpdir}/lib/migrations/#{basename}.rb")).to be_truthy
        expect(::File.exists?("#{tmpdir}/spec/lib/migrations/#{basename}_spec.rb")).to be_truthy
      end
    end

    context "with module" do
      let(:argv) { [ name, "--module", module_name ] }
      let(:outs) { [ "lib/migrations/#{module_name}/#{basename}" ] }

      it do
        expect(::File.exists?("#{tmpdir}/lib/migrations/#{module_name}/#{basename}.rb")).to be_truthy
        expect(::File.exists?("#{tmpdir}/spec/lib/migrations/#{module_name}/#{basename}_spec.rb")).to be_truthy
      end
    end
  end
end
