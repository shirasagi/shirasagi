class Cms::Elasticsearch::PageConvertor::OpendataApp < Cms::Elasticsearch::PageConvertor
  def initialize(item)
    @item = item.becomes_with_route
  end

  def convert_appfile_to_doc(appfile)
    file = appfile.file

    doc = {}
    doc[:url] = item.url
    doc[:name] = appfile.filename
    doc[:text] = appfile.text

    if file
      doc[:data] = Base64.strict_encode64(::File.binread(file.path))
      doc[:file] = {}
      doc[:file][:extname] = file.extname.upcase
      doc[:file][:size] = file.size
    end

    doc[:path] = item.path
    doc[:state] = item.state

    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = appfile.updated.try(:iso8601)
    doc[:created] = appfile.created.try(:iso8601)

    [ "file-#{file.id}", doc ]
  end

  def convert_files_to_docs
    docs = []
    item.appfiles.each do |appfile|
      docs << convert_appfile_to_doc(appfile)
    end
    docs
  end
end
