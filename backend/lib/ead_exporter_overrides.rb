# Add additional run_serialize_step call in serialize_digital_object
class EADSerializer < ASpaceExport::Serializer

  def serialize_digital_object(digital_object, xml, fragments)
    return if digital_object["publish"] === false && !@include_unpublished
    return if digital_object["suppressed"] === true

    # ANW-285: Only serialize file versions that are published, unless include_unpublished flag is set
    file_versions_to_display = digital_object['file_versions'].select {|fv| fv['publish'] == true || @include_unpublished }

    title = digital_object['title']
    date = digital_object['dates'][0] || {}

    atts = {}

    content = ""
    content << title if title
    content << ": " if date['expression'] || date['begin']
    if date['expression']
      content << date['expression']
    elsif date['begin']
      content << date['begin']
      if date['end'] != date['begin']
        content << "-#{date['end']}"
      end
    end

    atts['xlink:title'] = digital_object['title'] if digital_object['title']


    if file_versions_to_display.empty?
      atts['xlink:type'] = 'simple'
      atts['xlink:href'] = digital_object['digital_object_id']
      atts['xlink:actuate'] = 'onRequest'
      atts['xlink:show'] = 'new'
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object)
      xml.dao(atts) {
        xml.daodesc { sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    elsif file_versions_to_display.length == 1
      file_version = file_versions_to_display.first

      atts['xlink:type'] = 'simple'
      atts['xlink:actuate'] = file_version['xlink_actuate_attribute'] || 'onRequest'
      atts['xlink:show'] = file_version['xlink_show_attribute'] || 'new'
      atts['xlink:role'] = file_version['use_statement'] if file_version['use_statement']
      atts['xlink:href'] = file_version['file_uri']
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object, file_version)
      xml.dao(atts) {
        xml.daodesc { sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    else
      atts['xlink:type'] = 'extended'
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object)
      xml.daogrp( atts ) {
        xml.daodesc { sanitize_mixed_content(content, xml, fragments, true) } if content
        file_versions_to_display.each do |file_version|
          atts = {}
          atts['xlink:type'] = 'locator'
          atts['xlink:href'] = file_version['file_uri']
          atts['xlink:role'] = file_version['use_statement'] if file_version['use_statement']
          atts['xlink:title'] = file_version['caption'] if file_version['caption']
          atts['audience'] = 'internal' unless is_digital_object_published?(digital_object, file_version)
          xml.daoloc(atts)
        end
      }
    end
    # add run serializer step
    EADSerializer.run_serialize_step(digital_object, xml, fragments, :dao)
  end

end
