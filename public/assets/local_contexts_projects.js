/* local_context/public/assets/local_context.js */
class LocalContexts {
  constructor(project_ids) {
    this.publicPrefix = LOCALCONTEXTS_PUBLIC_PREFIX;
    this.lc_data_el_prefix = "lc-project-live-data-";
    this.spinner = '<div class="lds-ellipsis"><div></div><div></div><div></div><div></div></div>';
    this.lc_img_el = $('#main-content h1');
    this.lc_img_el.after(this.spinner)
    this.img_urls = Array();
    this.img_html = "";
    this.mainLanguage = typeof($('html').attr('lang')) !== 'undefined' ? $('html').attr('lang') : '';
    $('[id^=' + this.lc_data_el_prefix + ']').html('');

    this.fullDataTemplate = '<div ${label_language_tag}>' +
                            '<h4>${label_name}</h4>' +
                            '<p>' +
                            '<img class="local-contexts-image" src="${label_img_url}" alt="${label_img_alt}" />' +
                            '<span class="local-contexts-description">' +
                            '${label_audio}' +
                            '${label_default_text}' +
                            '${label_placed_by}' +
                            '${label_translations}' +
                            '</span>' +
                            '</p>' +
                            '</div>';

    this.translationsTemplate = '<span class="local-contexts-translation-wrapper well" ${translation_language_tag}>' +
                                '<span class="local-contexts-translation-title">${translation_title}</span>' +
                                '${translation_language}' +
                                '<span class="local-contexts-translation-translation">${translation_translation}</span>'  +
                                '</span>';

    this.placedByTemplate = '<span class="local-contexts-placed-by">' +
                            '<span class="local-contexts-placed-by-label">Placed by:</span> ${label_community}' +
                            '</span>';

    this.audioTemplate = '<span class="local-contexts-audio">' +
                          '<audio controls><src="${audioSrc}" />' +
                          'Your browser does not support HTML5 audio. Here is a <a href="${audioSrc}">link to the audio</a> instead.' +
                          '</audio></span>';

    const ids = JSON.parse(project_ids);
    if (ids.length > 0) {
      this.fetchLocalContextData(ids);
    }
  }

  fetchLocalContextData(ids) {
    const self = this;

    $.each(ids, function() {
      const current_id = this;
      $.ajax({
        url: self.publicPrefix + "local_contexts_projects/fetch/fetch_lc_project_data",
        data: {
          id: current_id,
          type: 'project',
          use_cache: true
        },
        dataType: 'json'
      })
      .done( function(data) {
        if (data !== null && data['unique_id'] == current_id) {
          self.parseLocalContextData(data, current_id);
        }
        else {
          self.renderLocalContextsError(current_id);
        }
      })
      .fail( function() {
        self.renderLocalContextsError(current_id);
      });
    });
  }

  parseLocalContextData(json, id) {
    const self = this;
    const lcNestedKeys = ['bc_labels','tk_labels','notice'];
    let new_json = {};
    const project_title = json['title']

    // labels
    $.each(lcNestedKeys, function() {
      if (json[this]) {
        new_json[this] = json[this];
      }
    });

    this.renderLocalContextsData(new_json, id, project_title);
  }

  renderLocalContextsData(new_json, id, project_title) {
    const self = this;

    $('a#lc-project-id-' + id).before('<h4 class="lc-project-title">Project Title: ' + project_title + '</h4>');

    let lc_data_html = "";
    let lc_img_html = "";
    let lc_img_wrapper = $('<div id="local-contexts-img-wrapper"><span id="lc-label-images-wrapper"></span><i class="fa fa-question-circle" data-toggle="tooltip" data-placement="right" title="Click an image to find out more about these Local Contexts Labels &amp; Notices."></i></div>');

    if ($('#local-contexts-img-wrapper').length == 0) {
      $('.lds-ellipsis').remove()
      this.lc_img_el.after(lc_img_wrapper);
    }

    $.each(new_json, function(k,v) {
      $.each(v, function(idx, label) {
        const labelLanguage = label.language_tag;
        let translations = '';

        if (typeof(label.default_text) !== 'undefined' && k == 'notice') {
          label['label_text'] = label.default_text;
        }

        if (label.translations && label.translations.length > 0) {
          translations = self.renderTranslations(label, labelLanguage);
        }

        lc_data_html += self.renderFullDataTemplate(label, labelLanguage, translations);

        if (!self.img_urls.includes(label.img_url)) {
          self.img_urls.push(label.img_url);
          const label_type = typeof(label.notice_type) !== 'undefined' ? 'Notice' : 'Label';

          lc_img_html += self.renderImageDataTemplate(label, label_type);
        }
      })
    });

    $('#' + this.lc_data_el_prefix + id).append(lc_data_html);
    this.img_html += lc_img_html;
    $('#lc-label-images-wrapper').html('').html(this.img_html);

    $('[data-toggle="tooltip"]').tooltip();
  }

  renderTranslations(data, labelLanguage) {

    const self = this;
    let translations_html  = '<span class="local-contexts-translation-toggle btn btn-xs btn-default">Hide/Show Translations for this Project</span>';

    $.each(data.translations, function() {
      let translationLanguageTag = '';
      let language = '';
      // check enclosing label language and then main language
      if (this.language_tag != '' && this.language_tag != labelLanguage) {
        translationLanguageTag = 'lang="' + this.language_tag + '"'
      }
      
      if (this.language != '') {
        language = self.renderTranslationLanguage(this.language);
      }
      translations_html += self.translationsTemplate
                              .replace('${translation_language_tag}', translationLanguageTag)
                              .replace('${translation_title}', this.translated_name + '&nbsp;')
                              .replace('${translation_language}', language)
                              .replace('${translation_translation}', this.translated_text);
    });

    return translations_html;
  }

  renderLocalContextsError(id) {
    const error_msg = '<span class="local-contexts-error-msg bg-danger">Unable to Fetch Local Contexts Data for this project.</span>';
    $('a#lc-project-id-' + id).after(error_msg);
  }

  renderFullDataTemplate(data, labelLanguage, translations) {
    let labelLanguageTag = '';
    let placedBy = '';
    let audio = '';

    if (labelLanguage != this.mainLanguage && labelLanguage != '') {
      labelLanguageTag = 'lang="' + data.language_tag + '"';
    }

    if (typeof(data.community) !== 'undefined') {
      placedBy = this.placedByTemplate.replace('${label_community}', data.community);
    }

    if (typeof(data.audiofile) != 'undefined' && data.audiofile != null) {
      audio = this.audioTemplate.replace(/\${audioSrc}/gi, data.audiofile);
    }

    const data_html = this.fullDataTemplate
                        .replace('${label_language_tag}', labelLanguageTag)
                        .replace('${label_placed_by}', placedBy)
                        .replace('${label_audio}', audio)
                        .replace('${label_name}', data.name)
                        .replace('${label_default_text}',data.label_text)
                        .replace('${label_img_url}', data.img_url)
                        .replace('${label_img_alt}', data.name)
                        .replace('${label_community}', data.community)
                        .replace('${label_translations}', translations);

    return data_html;
  }

  renderImageDataTemplate(data, label_type) {
    return '<img src="' + data.img_url + '" alt="' + data.name + '" title="Local Contexts ' + label_type + ': ' + data.name + '" class="local-contexts-header-image" />';
  }

  renderTranslationLanguage(language) {
    return '<span class="local-contexts-translation-language">(' + language + '</span>';
  }
}

class OpenToCollaborate {
  constructor(about_lc_text) {
    const self = this
    this.publicPrefix = LOCALCONTEXTS_PUBLIC_PREFIX
    $.ajax({
      url: this.publicPrefix + "local_contexts_projects/fetch/fetch_lc_project_data",
      data: {
        id: 'open_to_collaborate',
        type: 'open_to_collaborate',
        use_cache: true
      },
      dataType: 'json'
    })
    .done( function(data) {
      const otc = self.parse_open_to_collaborate(data, about_lc_text)
      $('#open-to-collaborate').html(otc);
    })
  }

  parse_open_to_collaborate(json, about_lc_text) {
    const otcHtml = '<h3>' + json.name + '</h3>' +
                  '<div><p>' +
                  '<img class="local-contexts-image" src="' + json.img_url + '" />' +
                  '<span class="local-contexts-description">' +
                  json.default_text + 
                  '<br /><br />' +
                  about_lc_text + 
                  '</span>' +
                  '</p></div>';

    return otcHtml;
  }
}


$().ready(function() {
  $('body').on('click', '#local-contexts-img-wrapper img', function() {
    offsetTop = $('.local-contexts-section').offset().top;
    window.scrollTo({top: offsetTop, behavior: 'smooth'})
  });

  $('body').on('click', '.local-contexts-translation-toggle', function() {
    const translation_container = $(this).siblings('.local-contexts-translation-wrapper');

    if (translation_container.hasClass('shown')) {
      translation_container.removeClass('shown');
    }

    else translation_container.addClass("shown");
  });
});
