class MARCModel < ASpaceExport::ExportModel
  attr_reader :aspace_record

  def initialize(obj, include_unpublished = false)
    @datafields = {}
    @include_unpublished = include_unpublished
    @aspace_record = obj
  end

  def self.from_aspace_object(obj, opts={})
    self.new(obj, opts[:include_unpublished])
  end

end
