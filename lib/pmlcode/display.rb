class PMLCode::Display

  INDENT = " " * 4

  def initialize(content, part, options)
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
    if @part && !line.in_part?(@part) && @options.verbose
      Rainbow(line.text).black
    elsif !@part || (@part && line.in_part?(@part))
      if line.highlighted?
        Rainbow(line.text).yellow.bold
      else
        line.text
      end
    end
  end

end
