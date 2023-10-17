require 'aspace_logger'

# TODO: Review and update if additional logic is needed to 
# handle multiple indicators and sufields
# or if text needs to be parsed in different ways by MARC field

class LocalContextsMARCSerialize

  DataField = Struct.new(:tag, :ind1, :ind2, :subfields)
  SubField = Struct.new(:code, :text)
  
  def initialize(record)
    @record = record
  end


  def datafields
    extra_fields = []
    
    if @record.aspace_record['local_contexts_projects']
      include_lcps = LocalContextsEADHelper.include_lcps?(@record.aspace_record['local_contexts_projects'])
      include_lcps.each do |lcp|        
        if lcp['_resolved'] && lcp['_resolved']['project_id'] && lcp['_resolved']['project_is_public'] === true
          project_id = lcp['_resolved']['project_id']
          project_url = File.join(AppConfig[:local_contexts_base_url], 'projects', project_id)
          project_ref = I18n.t("local_contexts_project.project_link_text") + " - Project ID and URL: " + project_id + ", " + project_url
          project_json = LocalContextsClient.new.get_data_from_local_contexts_api(project_id, 'project', true)
          lcp_preamble = project_json['title'] + " (" + project_ref + "). "
          construct_project_text(project_json, lcp_preamble).each do |marc_field|
            extra_fields << marc_field
          end
        end
      end
    end

    (@record.datafields + extra_fields).sort_by(&:tag)
  end

  def method_missing(*args)
    @record.send(*args)
  end

  def construct_project_text(project_json, lcp_preamble)
    project_marc = []
    lc_labels = ['bc_labels', 'tk_labels']
    project_json.each do |k,v|
      # labels
      if lc_labels.include?(k)
        v.each do |label|
          tag_number, indicator, subfield = marc_map(k, label['label_type'])
          project_preamble = lcp_preamble + label['name'] + " (" + label['language'] + "). "
          project_marc << DataField.new(tag_number, indicator, ' ', [SubField.new(subfield, project_preamble + project_contents(label))])
        end
      # notices
      elsif k == 'notice'
        v.each do |notice|
          tag_number, indicator, subfield = marc_map('notices', notice['notice_type'])
          project_preamble = lcp_preamble + notice['name'] + ". "
          project_marc << DataField.new(tag_number, indicator, ' ', [SubField.new(subfield, project_preamble + project_contents(notice))])
        end
      end
    end

    project_marc
  end

  def marc_map(label_or_notice, type)
    marc_map = AppConfig[:local_contexts_label_marc_tag_map][label_or_notice][type]
    tag_number = marc_map['tag_number']
    indicator = marc_map['indicator'].nil? ? ' ' : marc_map['indicator']
    subfield = marc_map['subfield']

    return tag_number, indicator, subfield
  end
  
  def project_contents(label_or_notice)
    contents = []
    if label_or_notice['label_text']
        contents << label_or_notice['label_text']
    end
    if label_or_notice['default_text']
        contents << label_or_notice['default_text']
    end
    if label_or_notice['community']
        contents << "Placed By: " + label_or_notice['community'] + "."
    end
    if label_or_notice['translations'] && label_or_notice['translations'].length > 0
      label_or_notice['translations'].each do |translation|
        contents << translation['translated_name']  + " (" + translation['language'] + ")."
        contents << translation['translated_text']
      end
    end
    contents << "Label or Notice Image URL: " + label_or_notice['img_url']

    contents.join(' ')
  end
  
end