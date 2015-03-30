require 'spec_helper'
require 'fileutils'

RSpec.describe SS::Migration, type: :model, dbscope: :example do
  def mkdir(dirname)
    FileUtils.mkdir_p dirname
  end

  def touch(filepath)
    File.open Rails.root.join(filepath), 'w'
  end

  def rm_rf(dirpath)
    FileUtils.rm_rf Rails.root.join(dirpath)
  end

  before(:all) { mkdir 'tmp/lib/migrations' }

  after(:all)  { rm_rf 'tmp/lib' }

  describe 'DIR constant' do
    it { expect(described_class::DIR.to_s).to match(/.*\/lib\/migrations$/) }
  end

  describe '.filepaths' do
    before do
      mkdir 'tmp/lib/migrations/mod1'
      mkdir 'tmp/lib/migrations/mod2'
      touch 'tmp/lib/migrations/mod2/20150324000000_a.rb'
      touch 'tmp/lib/migrations/mod1/20150324000001_a.rb'
      touch 'tmp/lib/migrations/mod1/20150324000002_a.rb'
      touch 'tmp/lib/migrations/mod2/20150324000003_a.rb'
      # ref.
      #   http://docs.ruby-lang.org/ja/2.2.0/method/Module/i/remove_const.html
      #   http://docs.ruby-lang.org/ja/2.2.0/class/Module.html#I_CLASS_EVAL
      SS::Migration.class_eval { remove_const :DIR }
      SS::Migration::DIR = Rails.root.join 'tmp/lib/migrations'
    end

    after do
      rm_rf 'tmp/lib/migrations/mod1'
      rm_rf 'tmp/lib/migrations/mod2'
    end

    it { expect(described_class.filepaths).to match [
      /.*\/mod2\/20150324000000_a\.rb$/,
      /.*\/mod1\/20150324000001_a\.rb$/,
      /.*\/mod1\/20150324000002_a\.rb$/,
      /.*\/mod2\/20150324000003_a\.rb$/,
    ] }
  end
end
