/* local_context/public/assets/local_context.js */

// All Local Contexts data comes from a third party, so it is escaped before it
// is put in markup, and urls are limited to http(s).
function lcEscapeHtml(value) {
  return String(value === null || typeof value === 'undefined' ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function lcSafeUrl(url) {
  return /^https?:\/\//i.test(url || '') ? url : '';
}

// A label's community is a name in some API versions and an object with a name in others.
function lcCommunityName(community) {
  if (community !== null && typeof community === 'object') {
    community = community.name;
  }
  return (community === null || typeof community === 'undefined') ? '' : String(community);
}

// The Open to Collaborate response nests the notice under 'notice'; accept a flat notice too.
function lcOtcNotice(data) {
  if (!data) { return null; }
  let notice = data.notice;
  if (Array.isArray(notice)) { notice = notice[0]; }
  return (notice && typeof notice === 'object') ? notice : data;
}

// Markup that contains text comes from the templates the PUI renders next to the
// script (public/views/local_contexts_project/_templates.html.erb), so the text
// can be localized with the locale files.
function lcTemplate(name) {
  const template = document.getElementById('lc-template-' + name);
  return template ? template.innerHTML.trim() : '';
}

// Fills ${name} placeholders. Uses a replacer function so "$&" and the like in the
// data are not treated as special replacement patterns. Values must already be safe markup.
function lcFill(template, values) {
  return template.replace(/\$\{(\w+)\}/g, function(match, key) {
    return Object.prototype.hasOwnProperty.call(values, key) ? values[key] : match;
  });
}

class LocalContexts {
  constructor(project_ids) {
    this.localCfgDefaults = this.checkLocalConfigDefaults()
    this.localTemplates = this.checkLocalTemplates()
    this.defaults = {
      cfg: this.localCfgDefaults ||= new LocalContextsCfgDefaults(),
      templates: this.localTemplates ||= new LocalContextsDefaultTemplates()
    }
    new LocalContextsInit(project_ids, this.defaults)
  }

  checkLocalConfigDefaults() {
    if (typeof LocalContextsLocalCfgDefaults === 'function') {
      return new LocalContextsLocalCfgDefaults()
    }
    else return false
  }

  checkLocalTemplates() {
    if (typeof LocalContextsLocalTemplates === 'function') {
      return new LocalContextsLocalTemplates()
    }
    else return false
  }
}

class LocalContextsCfgDefaults {
  constructor() {
    this.defaultCfg = this.defaultCfg()
  }

  defaultCfg() {
    return {
      headerSelector : $('#main-content h1')
    }
  }
}

class LocalContextsDefaultTemplates {
  constructor() {
    this.defaultDataTemplate = this.defaultDataTemplate()
    this.defaultAudioTemplate = this.defaultAudioTemplate()
    this.defaultPlacedByTemplate = this.defaultPlacedByTemplate()
    this.defaultTranslationsTemplate = this.defaultTranslationsTemplate()
  }

  defaultDataTemplate() {
    return  '<div ${label_language_tag}>' +
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
  }

  defaultTranslationsTemplate() {
    return  '<span class="local-contexts-translation-wrapper well" ${translation_language_tag}>' +
            '<span class="local-contexts-translation-title">${translation_title}</span>' +
            '${translation_language}' +
            '<span class="local-contexts-translation-translation">${translation_translation}</span>'  +
            '</span>';
  }

  defaultPlacedByTemplate() {
    return lcTemplate('placed-by');
  }

  defaultAudioTemplate() {
    return lcTemplate('audio');
  }
}

class LocalContextsInit {
  constructor(project_ids, defaults) {
    this.publicPrefix = LOCALCONTEXTS_PUBLIC_PREFIX;
    this.lc_data_el_prefix = "lc-project-live-data-";
    this.spinner = '<div class="lds-ellipsis"><div></div><div></div><div></div><div></div></div>';
    this.lc_img_el = defaults.cfg.defaultCfg.headerSelector
    this.lc_img_el.after(this.spinner)
    this.img_urls = Array();
    this.img_html = "";
    this.mainLanguage = typeof($('html').attr('lang')) !== 'undefined' ? $('html').attr('lang') : '';
    $('[id^=' + this.lc_data_el_prefix + ']').html('');

    this.fullDataTemplate = defaults.templates.defaultDataTemplate
    this.translationsTemplate = defaults.templates.defaultTranslationsTemplate
    this.placedByTemplate = defaults.templates.defaultPlacedByTemplate
    this.audioTemplate = defaults.templates.defaultAudioTemplate

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
      })    
      .always(() => {
        if ($('.lds-ellipsis').length > 0) {
          $('.lds-ellipsis').remove()
        }
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

    $(document.getElementById('lc-project-id-' + id)).parent('p').before(lcFill(lcTemplate('project-title'), {title: lcEscapeHtml(project_title)}));

    let lc_data_html = "";
    let lc_img_html = "";
    let lc_img_wrapper = $(lcTemplate('image-wrapper'));

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

        if (Array.isArray(label.translations) && label.translations.length > 0) {
          translations = self.renderTranslations(label, labelLanguage);
        }

        lc_data_html += self.renderFullDataTemplate(label, labelLanguage, translations);

        if (!self.img_urls.includes(label.img_url)) {
          self.img_urls.push(label.img_url);
          const label_type = lcTemplate(typeof(label.notice_type) !== 'undefined' ? 'label-type-notice' : 'label-type-label');

          lc_img_html += self.renderImageDataTemplate(label, label_type);
        }
      })
    });

    $(document.getElementById(this.lc_data_el_prefix + id)).append(lc_data_html);
    this.img_html += lc_img_html;
    $('#lc-label-images-wrapper').html('').html(this.img_html);

  }

  renderTranslations(data, labelLanguage) {

    const self = this;
    let translations_html  = lcTemplate('translation-toggle');

    $.each(data.translations, function() {
      let translationLanguageTag = '';
      let language = '';
      // check enclosing label language and then main language
      if (this.language_tag != '' && this.language_tag != labelLanguage) {
        translationLanguageTag = 'lang="' + lcEscapeHtml(this.language_tag) + '"'
      }
      
      if (this.language != '') {
        language = self.renderTranslationLanguage(this.language);
      }
      translations_html += lcFill(self.translationsTemplate, {
        translation_language_tag: translationLanguageTag,
        translation_title: lcEscapeHtml(this.translated_name) + '&nbsp;',
        translation_language: language,
        translation_translation: lcEscapeHtml(this.translated_text)
      });
    });

    return translations_html;
  }

  renderLocalContextsError(id) {
    $(document.getElementById('lc-project-id-' + id)).after(lcTemplate('error'));
  }

  renderFullDataTemplate(data, labelLanguage, translations) {
    let labelLanguageTag = '';
    let placedBy = '';
    let audio = '';

    if (labelLanguage != this.mainLanguage && labelLanguage != '') {
      labelLanguageTag = 'lang="' + lcEscapeHtml(data.language_tag) + '"';
    }

    const community = lcCommunityName(data.community);
    if (community !== '') {
      placedBy = lcFill(this.placedByTemplate, {label_community: lcEscapeHtml(community)});
    }

    if (lcSafeUrl(data.audiofile) != '') {
      audio = lcFill(this.audioTemplate, {audioSrc: lcEscapeHtml(lcSafeUrl(data.audiofile))});
    }

    return lcFill(this.fullDataTemplate, {
      label_language_tag: labelLanguageTag,
      label_placed_by: placedBy,
      label_audio: audio,
      label_name: lcEscapeHtml(data.name),
      label_default_text: lcEscapeHtml(data.label_text),
      label_img_url: lcEscapeHtml(lcSafeUrl(data.img_url)),
      label_img_alt: lcEscapeHtml(data.name),
      label_community: lcEscapeHtml(community),
      label_translations: translations
    });
  }

  renderImageDataTemplate(data, label_type) {
    return lcFill(lcTemplate('header-image'), {
      img_url: lcEscapeHtml(lcSafeUrl(data.img_url)),
      name: lcEscapeHtml(data.name),
      label_type: lcEscapeHtml(label_type)
    });
  }

  renderTranslationLanguage(language) {
    return '<span class="local-contexts-translation-language">(' + lcEscapeHtml(language) + ')</span>';
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
      const notice = lcOtcNotice(data);
      if (notice && notice.name) {
        $('#open-to-collaborate').html(self.parse_open_to_collaborate(notice, about_lc_text));
      }
    })
  }

  parse_open_to_collaborate(json, about_lc_text) {
    const otcHtml = '<h3>' + lcEscapeHtml(json.name) + '</h3>' +
                  '<div><p>' +
                  '<img class="local-contexts-image" src="' + lcEscapeHtml(lcSafeUrl(json.img_url)) + '" />' +
                  '<span class="local-contexts-description">' +
                  lcEscapeHtml(json.default_text) + 
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
