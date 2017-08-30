class PMLCode::Content
  include Enumerable

  def self.parse(text)
    parser = Parser.new(text)
    new(parser.result)
  end

  def initialize(lines)
    @lines = lines
  end

  def count
    @lines.size
  end

  def has_part?(name)
    @lines.any? { |l| l.in_part?(name) }
  end

  def each(&block)
    @lines.each(&block)
  end

  def to_s
    @lines.map(&:text)
  end

  class Line

    attr_reader :text

    LABEL_PATTERN = /^(?<plaintext>.*?)\s*(#|\/\/)?\s*<label\s+id[^>]+>\s*$/

    def initialize(text, parts = [], highlighted = false)
      @text = text
      @parts = parts
      @highlighted = highlighted
    end

    def has_label?
      plaintext != @text
    end

    def plaintext
      @plaintext ||= find_plaintext
    end

    def in_part?(part = nil)
      if part
        @parts.include?(part)
      else
        !@parts.empty?
      end
    end

    def highlighted?
      @highlighted
    end

    private

    def find_plaintext
      match = LABEL_PATTERN.match(@text)
      if match
        match[:plaintext]
      else
        @text
      end
    end

  end

  class Parser

    PART_START = /START:\s?(\S+)/
    PART_END = /END:\s?(\S+)/

    HL_START = /START_HIGHLIGHT/
    HL_END = /END_HIGHLIGHT/

    ELIDE = /<literal:elide>/

    def initialize(raw)
      @raw = raw
    end

    def result
      @result ||= run
    end

    private

    def run
      @parts = []
      @highlighted = nil
      lines.map(&method(:process)).compact
    end

    def process(text)
      case text
      when ELIDE
        nil
      when PART_START
        @parts << $1
        nil
      when PART_END
        @parts.reject! { |part| part == $1 }
        nil
      when HL_START
        @highlighted = true
        nil
      when HL_END
        @highlighted = false
        nil
      else
        Line.new(text, @parts.dup, @highlighted)
      end
    end

    def lines
      @raw.split(/\r?\n/)
    end

  end

end
