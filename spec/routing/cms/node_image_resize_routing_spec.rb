require 'spec_helper'

describe 'cms/node/image_resize routing', type: :routing do
  let(:site) { '1' }
  let(:cid) { 'node1' }

  it { expect(get: "/.s#{site}/cms#{cid}/image_resize").to route_to('cms/node/image_resizes#show', site: site, cid: cid) }
  it { expect(get: "/.s#{site}/cms#{cid}/image_resize/edit").to route_to('cms/node/image_resizes#edit', site: site, cid: cid) }
  it { expect(put: "/.s#{site}/cms#{cid}/image_resize").to route_to('cms/node/image_resizes#update', site: site, cid: cid) }
  it { expect(patch: "/.s#{site}/cms#{cid}/image_resize").to route_to('cms/node/image_resizes#update', site: site, cid: cid) }
  it { expect(delete: "/.s#{site}/cms#{cid}/image_resize").not_to route_to('cms/node/image_resizes#destroy') }
end
