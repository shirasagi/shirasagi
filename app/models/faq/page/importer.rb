class Faq::Page::Importer
  include Cms::PageImportBase

  self.model = Faq::Page

  private

  def create_importer
    @importer ||= SS::Csv.draw(:import, context: self, model: self.class.model) do |importer|
      define_importer_basic(importer)
      define_importer_meta(importer)
      define_importer_faq_question(importer)
      define_importer_body(importer)
      define_importer_category(importer)
      define_importer_parent_crumb(importer)
      define_importer_event_date(importer)
      define_importer_related_pages(importer)
      define_importer_contact_page(importer)
      define_importer_released(importer)
      define_importer_groups(importer)
      define_importer_state(importer)
    end.create
  end

  def define_importer_faq_question(importer)
    importer.simple_column :question
  end
end
