/* local_context/public/assets/local_context.js */
function LocalContexts(project_ids) {
  this.publicPrefix = LOCALCONTEXTS_PUBLIC_PREFIX;
  this.lc_data_el_prefix = "lc-project-live-data-";
  $('[id^=' + this.lc_data_el_prefix + ']').html('');
  this.lc_img_el = $('#main-content h1');
  this.img_urls = Array();
  this.img_html = "";
  this.mainLanguage = typeof($('html').attr('lang')) !== 'undefined' ? $('html').attr('lang') : '';


  this.fullDataTemplate = '<div ${label_language_tag}>' +
                          '<h4>${label_name}</h4>' +
                          '<p>' +
                          '<img class="local-context-image" src="${label_img_url}" />' +
                          '<span class="local-context-description">' +
                          '${label_default_text}' +
                          '</span>' +
                          '</p>' +
                          '</div>';

  this.translationsTemplate = '<span class="local-context-translation-wrapper well" ${translation_language_tag}>' +
                              '<span class="local-context-translation-title">${translation_title}</span>' +
                              '<span class="local-context-translation-language">(${translation_language})</span>' +
                              '<span class="local-context-translation-translation">${translation_translation}</span>'  +
                              '</span>';

  ids = JSON.parse(project_ids);
  if (ids.length > 0) {
     this.fetchLocalContextData(ids);
  }
}

LocalContexts.prototype.fetchLocalContextData = function(ids) {
  var self = this;

  $.each(ids, function() {
    var current_id = this;
    $.ajax({
      url: self.publicPrefix + "local_contexts_projects/fetch/fetch_lc_project_data",
      data: {
        id: current_id,
        type: 'project'
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

LocalContexts.prototype.parseLocalContextData = function(json, id) {
  var self = this;
  var lcNestedKeys = ['bc_labels','tk_labels','notice'];
  var new_json = {};
  var project_title = json['title']

  // labels
  $.each(lcNestedKeys, function() {
    if (json[this]) {
      new_json[this] = json[this];
    }
  });

  this.renderLocalContextsData(new_json, id, project_title);
}

LocalContexts.prototype.renderLocalContextsData = function(new_json, id, project_title) {
  var self = this;

  $('a#lc-project-id-' + id).before('<h4 class="lc-project-title">Project Title: ' + project_title + '</h4>');

  var lc_data_html = "";
  var lc_img_html = "";
  var lc_img_wrapper = $('<div id="local-contexts-img-wrapper"><span id="lc-label-images-wrapper"></span><i class="fa fa-question-circle" data-toggle="tooltip" data-placement="right" title="Click an image to find out more about these Local Contexts Labels &amp; Notices."></i></div>');

  if ($('#local-contexts-img-wrapper').length == 0) {
    this.lc_img_el.after(lc_img_wrapper);
  }

  $.each(new_json, function(k,v) {
    $.each(v, function(idx, label) {
      if (typeof(label.default_text) !== 'undefined' && k == 'notice') {
        label['label_text'] = label.default_text;
      }
      var labelLanguage = label.language_tag;
      lc_data_html += self.renderFullDataTemplate(label, labelLanguage);

      if (label.translations && label.translations.length > 0) {
        lc_data_html += self.renderTranslations(label, labelLanguage);
      }

      if (!self.img_urls.includes(label.img_url)) {
        self.img_urls.push(label.img_url);
        lc_img_html += self.renderImageDataTemplate(label);
      }
    })
  });

  $('#' + this.lc_data_el_prefix + id).append(lc_data_html);
  this.img_html += lc_img_html;
  $('#lc-label-images-wrapper').html('').html(this.img_html);

  $('[data-toggle="tooltip"]').tooltip();
}

LocalContexts.prototype.renderTranslations = function(data, labelLanguage) {

  var self = this;
  var translations_html  = '<span class="local-context-translation-toggle btn btn-xs btn-default">Hide/Show Translations for this Project</span>';

  $.each(data.translations, function() {
    var translationLanguageTag = '';

    // check enclosing label language and then main language
    if (this.language_tag != '' && this.language_tag != labelLanguage) {
      translationLanguageTag = 'lang="' + this.language_tag + '"'
    }
    translations_html += self.translationsTemplate
                             .replace('${translation_language_tag}', translationLanguageTag)
                             .replace('${translation_title}', this.translated_name + '&nbsp;')
                             .replace('${translation_language}', this.language)
                             .replace('${translation_translation}', this.translated_text);
  });

  return translations_html;
}

LocalContexts.prototype.renderLocalContextsError = function(id) {
  var error_msg = '<span class="local-contexts-error-msg bg-danger">Unable to Fetch Local Contexts Data for this project.</span>';
  $('a#lc-project-id-' + id).after(error_msg);
}

LocalContexts.prototype.renderFullDataTemplate = function(data, labelLanguage) {
  var labelLanguageTag = '';

  if (labelLanguage != this.mainLanguage && labelLanguage != '') {
     labelLanguageTag = 'lang="' + data.language_tag + '"';
  }
  var data_html = this.fullDataTemplate
                      .replace('${label_language_tag}', labelLanguageTag)
                      .replace('${label_name}', data.name)
                      .replace('${label_default_text}',data.label_text)
                      .replace('${label_img_url}', data.img_url)
                      .replace('${label_community}', data.community);

  return data_html;
}

LocalContexts.prototype.renderImageDataTemplate = function(data) {
  return '<img src="' + data.img_url + '" alt="' + data.name + '" class="local-contexts-header-image" />';
}

function OpenToCollaborate(about_lc_text) {
  var self = this
  this.publicPrefix = LOCALCONTEXTS_PUBLIC_PREFIX
  $.ajax({
    url: this.publicPrefix + "local_contexts_projects/fetch/fetch_lc_project_data",
    data: {
      id: 'no_id',
      type: 'open_to_collaborate'
    },
    dataType: 'json'
  })
  .done( function(data) {
    var otc = self.parse_open_to_collaborate(data, about_lc_text)
    $('#open-to-collaborate').html(otc);
  })
}

OpenToCollaborate.prototype.parse_open_to_collaborate = function(json, about_lc_text) {
  var otcHtml = '<h3>' + json.name + '</h3>' +
                '<div><p>' +
                '<img class="local-context-image" src="' + json.img_url + '" />' +
                '<span class="local-context-description">' +
                json.default_text + 
                '<br /><br />' +
                about_lc_text + 
                '</span>' +
                '</p></div>';

  return otcHtml;
}


$().ready(function() {
  $('body').on('click', '#local-contexts-img-wrapper img', function() {
    offsetTop = $('.local-contexts-section').offset().top;
    window.scrollTo({top: offsetTop, behavior: 'smooth'})
  });

  $('body').on('click', '.local-context-translation-toggle', function() {
    var translation_container = $(this).siblings('.local-context-translation-wrapper');

    if (translation_container.hasClass('shown')) {
      translation_container.removeClass('shown');
    }

    else translation_container.addClass("shown");
  });
});
