class PMLCode::Content
  include Enumerable

  def self.parse(text)
    parser = Parser.new(text)
    new(parser.result)
  end

  def initialize(lines)
    @lines = lines
  end

  def has_part?(name)
    @lines.any? { |l| l.part == name }
  end

  def each(&block)
    @lines.each(&block)
  end

  def to_s
    @lines.map(&:text)
  end

  class Line

    attr_reader :text, :part

    def initialize(text, part, highlighted = false)
      @text = text
      @part = part
      @highlighted = highlighted
    end

    def highlighted?
      @highlighted
    end

  end

  class Parser

    PART_START = /START:\s?(\S+)/
    PART_END = /END:\s?(\S+)/

    HL_START = /START_HIGHLIGHT/
    HL_END = /END_HIGHLIGHT/

    def initialize(raw)
      @raw = raw
    end

    def result
      @result ||= run
    end

    private

    def run
      @part = nil
      @highlighted = nil
      lines.map(&method(:process)).compact
    end

    def process(text)
      case text
      when PART_START
        @part = $1
        nil
      when PART_END
        @part = nil
        nil
      when HL_START
        @highlighted = true
        nil
      when HL_END
        @highlighted = false
        nil
      else
        Line.new(text, @part, @highlighted)
      end
    end

    def lines
      @raw.split(/\r?\n/)
    end

  end

end
