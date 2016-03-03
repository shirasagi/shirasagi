require 'spec_helper'

describe Cms::Part, type: :model, dbscope: :example do
  let(:item) { create :cms_part }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Base, type: :model, dbscope: :example do
  let(:item) { create :cms_part_base }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Free, type: :model, dbscope: :example do
  let(:item) { create :cms_part_free }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Node, type: :model, dbscope: :example do
  let(:item) { create :cms_part_node }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Page, type: :model, dbscope: :example do
  let(:item) { create :cms_part_page }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Tabs, type: :model, dbscope: :example do
  let(:item) { create :cms_part_tabs }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Crumb, type: :model, dbscope: :example do
  let(:item) { create :cms_part_crumb }
  it_behaves_like "cms_part#spec"
end
