class PMLCode::Display

  INDENT = " " * 4

  def initialize(content, part, options = {})
    @content = content
    @part = part
    @options = options
  end

  def to_s
    INDENT + "```\n" + \
    @content.map(&method(:format_line)).compact.map { |l| INDENT + l }.join("\n") + "\n" + \
    INDENT + "```"
  end

  private

  def format_line(line)
    if @part && line.part != @part && @options[:expanded]
      Rainbow(line.text).black
    elsif line.highlighted?
      Rainbow(line.text).yellow.bold
    else
      line.text
    end
  end

end
