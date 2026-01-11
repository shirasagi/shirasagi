require 'spec_helper'

describe 'sys/image_resize routing', type: :routing do
  it { expect(get: '/.sys/image_resize').to route_to('sys/image_resizes#show') }
  it { expect(get: '/.sys/image_resize/edit').to route_to('sys/image_resizes#edit') }
  it { expect(put: '/.sys/image_resize').to route_to('sys/image_resizes#update') }
  it { expect(patch: '/.sys/image_resize').to route_to('sys/image_resizes#update') }
  it { expect(delete: '/.sys/image_resize').not_to route_to('sys/image_resizes#destroy') }
end
