require "nokogiri"
require "rainbow"

require "fileutils"
require "open3"

require "pmlcode/version"

module PMLCode
  autoload :CLI,     'pmlcode/cli'
  autoload :Updater, 'pmlcode/updater'
  autoload :Content, 'pmlcode/content'
  autoload :Display, 'pmlcode/display'
  autoload :Source,  'pmlcode/source'
  autoload :ExportCommand, 'pmlcode/export_command'
  autoload :UpdateCommand, 'pmlcode/update_command'
end
