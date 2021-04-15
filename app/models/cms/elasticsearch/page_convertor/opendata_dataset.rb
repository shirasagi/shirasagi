class Cms::Elasticsearch::PageConvertor::OpendataDataset < Cms::Elasticsearch::PageConvertor
  def initialize(item)
    @item = item.becomes_with_route
  end

  def convert_resource_to_doc(resource)
    file = resource.file

    doc = {}
    doc[:url] = item.url
    doc[:name] = resource.name
    doc[:text] = resource.text

    if file
      doc[:data] = Base64.strict_encode64(::File.binread(file.path))
      doc[:file] = {}
      doc[:file][:extname] = file.extname.upcase
      doc[:file][:size] = file.size
    end

    doc[:path] = item.path
    doc[:state] = item.state

    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = resource.updated.try(:iso8601)
    doc[:created] = resource.created.try(:iso8601)

    [ "file-#{file.id}", doc ]
  end

  def convert_files_to_docs
    docs = []
    item.resources.each do |resource|
      docs << convert_resource_to_doc(resource)
    end
    docs
  end
end
