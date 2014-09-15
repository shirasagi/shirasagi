require 'spec_helper'

describe Cms::Part do
  subject(:model) { Cms::Part }
  subject(:factory) { :cms_part }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }

    it { expect(item.becomes_with_route).not_to eq nil }
    it { expect(item.dirname).to eq nil }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.json_path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parent).to eq false }
  end
end

describe Cms::Part::Base do
  subject(:model) { Cms::Part::Base }
  subject(:factory) { :cms_part_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Cms::Part::Free do
  subject(:model) { Cms::Part::Free }
  subject(:factory) { :cms_part_free }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Cms::Part::Node do
  subject(:model) { Cms::Part::Node }
  subject(:factory) { :cms_part_node }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Cms::Part::Page do
  subject(:model) { Cms::Part::Page }
  subject(:factory) { :cms_part_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Cms::Part::Tabs do
  subject(:model) { Cms::Part::Tabs }
  subject(:factory) { :cms_part_tabs }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Cms::Part::Crumb do
  subject(:model) { Cms::Part::Crumb }
  subject(:factory) { :cms_part_crumb }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
