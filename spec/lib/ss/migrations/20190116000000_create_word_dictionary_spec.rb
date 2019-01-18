require 'spec_helper'
require Rails.root.join('lib/migrations/cms/20190116000000_create_word_dictionary.rb')

RSpec.describe SS::Migration20190116000000, dbscope: :example do
  before do
    site1 = create :cms_site_unique
    site2 = create :cms_site_unique
    site3 = create :cms_site_unique
  end

  it do
    expect { described_class.new.change }
      .to change { Cms::WordDictionary.count }.by 3
  end
end
