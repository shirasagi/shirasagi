module SS
  # HTTP Chunk Response Reader
  class ChunkReader
    include Enumerable

    def initialize(chunk)
      @io = StringIO.new(chunk)
    end

    def each
      loop do
        size = read_chunk_size
        break if size == 0

        yield @io.read(size)

        read_crlf
      end
    end

    private

    def read_chunk_size
      size = ""

      loop do
        chr = @io.read(1)
        break if chr == "\r"
        size << chr
      end

      raise "invalid chunk" if @io.read(1) != "\n"
      raise "invalid chunk" if size.empty?

      Integer(size, 16)
    end

    def read_crlf
      # CRLF means end of a chunk
      raise "invalid chunk" if @io.read(1) != "\r"
      raise "invalid chunk" if @io.read(1) != "\n"
    end
  end
end
