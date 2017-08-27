class PMLCode::Source

  PATTERN = /^(?<path>.+?)(:(?<line>\d+):?)?$/

  def self.parse(text)
    if (match = text.match(PATTERN))
      new(match[:path], match[:line] ? Integer(match[:line]) : nil)
    end
  end

  attr_reader :path, :line
  def initialize(path, line)
    @path = File.expand_path(path)
    @line = line
  end

  def missing?
    !File.exists?(@path)
  end

  def to_s
    [@path, @line].join(":")
  end

end
