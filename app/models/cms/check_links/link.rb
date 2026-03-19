module Cms::CheckLinks
  Link = Data.define(:full_url, :href, :offset, :inner_yield) do
    def meta
      { offset: offset, inner_yield: inner_yield }
    end
  end

  LinkWithSource = Data.define(:source, :link) do
    delegate :full_url, :status, to: :source
    delegate :href, :offset, :inner_yield, :meta, to: :link
  end
end
