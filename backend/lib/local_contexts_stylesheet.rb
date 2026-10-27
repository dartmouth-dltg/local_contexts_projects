require 'fileutils'

# Keeps the staff EAD to PDF stylesheet in the main stylesheet directory in step
# with the plugin's version, which adds rendering for Local Contexts images.
#
# This runs on every startup and decides by comparing files, not by whether it
# has run before, so that
#  - a newer plugin stylesheet replaces an older installed copy
#  - a stylesheet replaced by an ArchivesSpace upgrade is backed up and replaced
#    again, rather than silently losing the Local Contexts rendering
module LocalContextsStylesheet

  FILENAME = 'as-ead-pdf.xsl'
  BACKUP_FILENAME = 'as-ead-pdf-lc-moved-orig.xsl'

  # present in every version of the plugin stylesheet, absent from core ones
  MARKER = 'Local Contexts start'

  PLUGIN_DIR = File.expand_path('../../..', __FILE__)

  # Returns :current, :installed or :updated.
  #  :installed - there was no stylesheet, or one that is not ours, which was
  #               backed up first
  #  :updated   - an older plugin stylesheet was replaced (the backup is untouched)
  def self.install(logger, base_dir = ASUtils.find_base_directory, plugin_dir = PLUGIN_DIR)
    target = File.join(base_dir, 'stylesheets', FILENAME)
    backup = File.join(base_dir, 'stylesheets', BACKUP_FILENAME)
    source = File.join(plugin_dir, 'stylesheets', FILENAME)

    unless File.file?(source)
      logger.error("Local Contexts EAD to PDF stylesheet not found at #{source}")
      return nil
    end

    if File.file?(target) && FileUtils.identical?(source, target)
      logger.info("Local Contexts EAD to PDF stylesheet is up to date")
      return :current
    end

    result = File.file?(target) ? :updated : :installed
    if File.file?(target) && !File.read(target).include?(MARKER)
      # not ours: keep it as the backup (replacing the backup of an older stylesheet)
      FileUtils.cp(target, backup)
      logger.info("Backed up the EAD to PDF stylesheet as #{BACKUP_FILENAME}")
      result = :installed
    end

    # copy next to the target and rename, so the stylesheet is never missing
    tmp = "#{target}.lc-tmp"
    FileUtils.cp(source, tmp)
    File.rename(tmp, target)
    logger.info("Installed the Local Contexts EAD to PDF stylesheet (#{result})")

    result
  end

end
