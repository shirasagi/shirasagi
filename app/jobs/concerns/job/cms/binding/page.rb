module Job::Cms::Binding::Page
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

  def bind(bindings)
    if bindings['page_id'].present?
      self.page_id = bindings['page_id'].to_param
      @page = nil
    end
    super
  end

  def bindings
    ret = super
    ret.merge!({ 'page_id' => page_id }) if page_id.present?
    ret
  end
end
