class PMLCode::SparseUpdater < PMLCode::Updater

  handles do |criteria|
    criteria.type == :sparse
  end

  private

  def update(match, already_wrote)
    success = false
    content = nil
    Dir.chdir(@options.app) do
      content = `git show origin/#{match[:chapter]}.#{match[:snapshot]}:#{match[:path]}`
      success = $?.success?
    end
    if success
      unless already_wrote || @options.dry_run
        full_path = File.join(directory(match), match[:path])
        FileUtils.mkdir_p(File.dirname(full_path))
        File.open(full_path, 'w') do |f|
          f.write(content)
        end
      end
      content
    end
  end

  def generate_update_id(match)
    "#{match[:chapter]}.#{match[:snapshot]}/#{match[:path]}"
  end

end
