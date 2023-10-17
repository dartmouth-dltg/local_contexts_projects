require 'aspace_logger'
class LcpHelpers
  def find_as_version
    version = File.join(*[ ASUtils.find_base_directory, 'ARCHIVESSPACE_VERSION'])
    return normalize_as_version(File.read(version).chomp) if File.file? version

    return '3.1.x'
  end

  def normalize_as_version(version)
    version_num = version.gsub('v','').nil? ? 3.1 : version.gsub('v','').to_f
    case version_num
    when 3.3...3.4
      return '3.3.x'
    when 3.2...3.3
      return '3.2.x'
    else
      return '3.1.x'
    end
  end
end