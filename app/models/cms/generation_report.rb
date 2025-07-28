module Cms::GenerationReport
  module_function

  def sha256_hash(file_path)
    head = ::File.binread(file_path, 1_024)
    Digest::SHA256.hexdigest(head)
  end
end
