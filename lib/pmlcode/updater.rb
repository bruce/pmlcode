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
    @pml = options.pml
    @options = options
    @current_prefix = nil
    @wrote = {}
  end

  def embeds
    @embeds ||= begin
      doc = Nokogiri::XML(File.read(@pml))
      doc.css('embed')
    end
  end

  def run
    embeds.each do |embed|
      puts Rainbow(File.basename(@pml) + ":#{embed.line} ").bold.underline
      match = @options.pattern.match(embed[:file])
      if match
        text = dedup(match) { update(match) }
        if text
          print Rainbow("OK").green
          puts " : FILE #{embed[:file]}"
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
    id = generate_update_id(match)
    if @wrote[id]
      @wrote[id]
    else
      if (text = block.())
        @wrote[id] = text
        text
      end
    end
  end

  def check_part!(text, part)
    if part
      content = PMLCode::Content.parse(text)
      if content.has_part?(part)
        print Rainbow("OK").green
      else
        print Rainbow("MISSING").red
      end
    else
      print Rainbow("--").gray
    end
    puts " : PART #{part}"
  end

  def generate_update_id(match)
    raise NotImplemented, "Override #{self.class}#generate_update_id"
  end

  def directory(match)
    File.expand_path(File.join(@options.output, match[:coderoot], match[:chapter], match[:snapshot]))
  end

end
