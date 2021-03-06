class PMLCode::Updater

  class << self

    def inherited(plugin)
      plugins << plugin
    end

    def plugins
      @plugins ||= []
    end

    def load_plugins!
      Dir.glob(File.expand_path("../updaters/*.rb", __FILE__)) do |filename|
        require filename
      end
    end

    def handle_check
      @handle_check ||= ->(x) { false }
    end

    def handles(&check)
      @handle_check = check
    end

    def handles?(criteria)
      handle_check.(criteria)
    end

    def find(criteria)
      load_plugins!
      plugins.find do |plugin|
        plugin.handles?(criteria)
      end
    end

    def run(options)
      new(options).run
    end

  end

  def initialize(options)
    @source = options.source
    @options = options
    @current_prefix = nil
    @wrote = {}
    @files = {}
  end

  def embeds
    @embeds ||= begin
      doc = Nokogiri::XML(File.read(@source.path))
      doc.css('embed').select do |embed|
        if @source.line
          embed.line == @source.line
        else
          true
        end
      end
    end
  end

  def run
    embeds.each do |embed|
      puts Rainbow(File.basename(@source.path) + ":#{embed.line} ").bold.underline
      match = @options.pattern.match(embed[:file])
      if match
        text = dedup(match) { |already_wrote| update(match, already_wrote) }
        if text
          print Rainbow("OK").green
          puts " : FILE #{embed[:file]} #{write_flag}"
          check_part!(text, embed[:part])
        else
          print Rainbow("ERROR").red
          puts " : FILE #{embed[:file]}"
        end
      else
        print Rainbow("BAD MATCH").red
        puts " : FILE #{embed[:file]}"
      end
      puts
    end
  end

  def dedup(match, &block)
    update_id = generate_update_id(match)
    content_id = generate_content_id(match)
    @files[content_id] ||= block.(@wrote[update_id])
    @wrote[update_id] = true
    @files[content_id]
  end

  def check_part!(text, part)
    content = PMLCode::Content.parse(text)
    if part
      if content.has_part?(part)
        print Rainbow("OK").green
      else
        print Rainbow("MISSING").red
      end
    else
      print Rainbow("--").gray
    end
    puts " : PART #{part}"
    puts "\n"
    if @options.content
      puts PMLCode::Display.new(content, part, @options)
    end
  end

  def write_flag
    if @options.dry_run
      Rainbow("  DRY RUN  ").green.inverse
    else
      Rainbow("  WRITTEN  ").yellow.inverse
    end
  end

  def generate_content_id(match)
    match.string
  end

  def generate_update_id(match)
    raise NotImplemented, "Override #{self.class}#generate_update_id"
  end

  def directory(match)
    File.expand_path(File.join(@options.output, match[:coderoot], match[:chapter], match[:snapshot]))
  end

end
