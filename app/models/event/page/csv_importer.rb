class Event::Page::CsvImporter
  include Cms::PageImportBase

  self.model = Event::Page

  private

  def create_importer
    @importer ||= SS::Csv.draw(:import, context: self, model: self.class.model) do |importer|
      define_importer_basic(importer)
      define_importer_meta(importer)
      define_importer_body(importer)
      define_importer_category(importer)
      define_importer_parent_crumb(importer)
      define_importer_event_body(importer)
      define_importer_event_date(importer)
      define_importer_related_pages(importer)
      # define_importer_contact_page(importer)
      define_importer_released(importer)
      define_importer_groups(importer)
      define_importer_state(importer)
      # define_importer_forms(importer)
    end.create
  end

  def define_importer_event_body(importer)
    importer.simple_column :schedule
    importer.simple_column :venue
    importer.simple_column :content
    importer.simple_column :cost
    importer.simple_column :related_url
    importer.simple_column :contact
  end
end
