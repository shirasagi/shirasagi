module Job::Cms::Reference::Page
  extend ActiveSupport::Concern

  included do
    # page class
    mattr_accessor(:page_class, instance_accessor: false) { Cms::Page }
    # page
    attr_accessor :page_id
  end

  def page
    return nil if page_id.blank?
    @page ||= begin
      page = self.class.page_class.find(page_id) rescue nil
      if page
        page = page.becomes_with_route rescue page
      end
      page
    end
  end
end
