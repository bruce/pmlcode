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

  def log(location, text)
    $stderr.puts "#{location}#{text}"
  end

  def run
    embeds.each do |embed|
      location = File.basename(@pml) + ":#{embed.line}:"
      match = @options.pattern.match(embed[:file])
      if match
        dedup(location, match) { update(match) }
      else
        log location, "NOMATCH #{embed[:file]}"
      end
    end
  end

  def dedup(location, match, &block)
    id = generate_update_id(match)
    if @wrote[id]
      log location, "SKIP #{id} (WROTE by #{@wrote[id][0..-2]})"
    else
      if block.()
        @wrote[id] = location
        log location, "WROTE #{id}"
      else
        log location, "INVALID #{id}"
      end
    end
  end

  def generate_update_id(match)
    raise NotImplemented, "Override #{self.class}#generate_update_id"
  end

  def directory(match)
    File.expand_path(File.join(@options.output, match[:coderoot], match[:chapter], match[:snapshot]))
  end

end
