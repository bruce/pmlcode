class PMLCode::ExportCommand

  def self.run(options)
    check_path!(options.export)
    new(options).run
  end

  def self.check_path!(path)
    if File.exists?(path)
      abort "Sorry, #{path} exists and I don't know how to update yet."
    end
  end

  def initialize(options)
    @app = options.app
    @path = options.export
  end

  def run
    FileUtils.mkdir_p(@path)
    Dir.chdir @path do
      command "git init"
    end
    branches.each do |branch|
      Dir.chdir @path do
        command "git checkout -b '#{branch}'"
      end
      Dir.chdir @app do
        command "git archive 'origin/#{branch}' | tar -x -C '#{@path}'"
      end
      Dir.chdir @path do
        Dir['**/*'].each do |filename|
          if File.file?(filename)
            cleanup(filename)
          end
        end
        command "git add ."
        command "git commit -m '#{branch}'", /working tree clean/
      end
    end
  end

  def cleanup(filename)
    lines = File.readlines(filename)
    line_count = lines.size
    content = PMLCode::Content.parse(lines.join(""))
    if line_count == content.count && !content.any? { |line| line.has_label? }
      return
    else
      File.open(filename, 'w') do |f|
        content.each do |line|
          f.puts line.plaintext
        end
      end
    end
  end

  def command(cmd, okay_pattern = nil)
    text, status = Open3.capture2(cmd)
    if status.success?
      true
    elsif okay_pattern && text.match(okay_pattern)
      true
    else
      abort "Could not run: #{cmd}"
    end
  end

  def branches
    @branches ||= Dir.chdir(@app) {
      `git ls-remote --heads origin`
    }.scan(/refs\/heads\/(\d+-\S+?\.\S+\.\d+-\S+?)$/).flatten.sort
  end

end
