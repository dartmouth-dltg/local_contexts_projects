require 'aspace_logger'

class EADLocalContextsSerialize < EADSerializer

  def call(data, xml, fragments, context)
    lcp_ead = LocalContextsEAD.new
    if context == :did
      if data.json && data.json['jsonmodel_type'] == 'resource'
        lcp_ead.serialize_local_contexts_collaborate(data, xml, fragments)
      end
    end

    if context == :archdesc
      lcp_ead.serialize_local_contexts_ead(data, xml, fragments)
    end

    if context == :dao
      lcp_ead.serialize_local_contexts_ead_for_digital_objects(data, xml, fragments)
    end
  end

end

class EAD3LocalContextsSerialize < EAD3Serializer

  def call(data, xml, fragments, context)
    lcp_ead3 = LocalContextsEAD3.new

    if context == :did
      if data.json && data.json['jsonmodel_type'] == 'resource'
        lcp_ead3.serialize_local_contexts_collaborate(data, xml, fragments)
      end
    end

    if context == :archdesc
      lcp_ead3.serialize_local_contexts_ead(data, xml, fragments)
    end

    if context == :dao
      lcp_ead3.serialize_local_contexts_ead_for_digital_objects(data, xml, fragments)
    end

  end

end