/* local_context/public/assets/local_context.js */
function LocalContexts(project_ids) {
  this.lc_data_el_prefix = "lc-project-live-data-";
  $('[id^=' + this.lc_data_el_prefix + ']').html('');
  this.lc_img_el = $('#main-content h1');
  this.img_urls = Array();
  this.img_html = "";
  this.mainLanguage = typeof($('html').attr('lang')) !== 'undefined' ? $('html').attr('lang') : '';


  this.fullDataTemplate = '<div {$label_language_tag}>' +
                          '<h4>${label_name}</h4>' +
                          '<p>' +
                          '<img class="local-context-image" src="${label_img_url}" />' +
                          '<span class="local-context-description">' +
                          '${label_default_text}' +
                          '<span class="local-context-placed-by">' +
                          '<span class="local-context-placed-by-label">Placed by:</span> ${label_community}' +
                          '</span>' +
                          '</span>' +
                          '</p>' +
                          '</div>';

  this.translationsTemplate = '<span class="local-context-translation-wrapper well" {$translation_language_tag}>' +
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
      url: APP_PATH + "local_contexts_projects/fetch/fetch_lc_project_data",
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

  /**
   * Comment the above and uncomment below for testing purposes
   */
  // var sampleData = {"unique_id":"259854f7-b261-4c8c-8556-4b153deebc18","title":"Sample Project","bc_labels":[{"name":"BC Provenance (BC P) Sample Label","label_type":"provenance","default_text":"This SAMPLE Label is being used to affirm an inherent interest Indigenous people have in the scientific collections and data about communities, peoples, and the biodiversity found within traditional lands, waters and territories. [Community name or authorizing party] has permissioned the use of this collection and associated data for research purposes, and retains the right to be named and associated with it into the future. This association reflects a significant relationship and responsibility to [the species or biological entity] and associated scientific collections and data. This is a sample Label that is only used for example purposes.","img_url":"https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/bclabels/bc-provenance.png","community":"Sample Community","translations":[],"created":"2021-10-22T18:13:21.042197Z","updated":"2021-10-22T18:14:13.252527Z"}],"tk_labels":[{"name":"TK Creative (TK CR) Sample Label","label_type":"creative","default_text":"This SAMPLE Label is being used to acknowledge the relationship between the creative practices of [name] and [community name] and the associated cultural responsibilities. This is a sample Label used for examples only.","img_url":"https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/tklabels/tk-creative.png","community":"Sample Community","translations":[],"created":"2021-10-22T18:19:02.104252Z","updated":"2021-10-22T18:25:49.578629Z"},{"name":"TK Attribution (TK A) Sample Label","label_type":"attribution","default_text":"This SAMPLE label is being used to correct historical mistakes or exclusions pertaining to this material. This is especially in relation to the names of the people involved in performing or making this work and/or correctly naming the community from which it originally derives. As a user you are being asked to also apply the correct attribution in any future use of this work. This is a sample Label used for example purposes only.","img_url":"https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/tklabels/tk-attribution.png","community":"Sample Community","translations":[],"created":"2021-10-22T18:12:04.455640Z","updated":"2021-10-22T18:13:59.447271Z"}],"notice":[{"notice_type":"biocultural_and_traditional_knowledge","bc_img_url":"https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/bc-notice.png","bc_default_text":"The BC (Biocultural) Notice is a visible notification that there are accompanying cultural rights and responsibilities that need further attention for any future sharing and use of this material or data. The BC Notice recognizes the rights of Indigenous peoples to permission the use of information, collections, data and digital sequence information (DSI) generated from the biodiversity or genetic resources associated with traditional lands, waters, and territories. The BC Notice may indicate that BC Labels are in development and their implementation is being negotiated.","tk_img_url":"https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/tk-notice.png","tk_default_text":"The TK (Traditional Knowledge) Notice is a visible notification that there are accompanying cultural rights and responsibilities that need further attention for any future sharing and use of this material. The TK Notice may indicate that TK Labels are in development and their implementation is being negotiated.","placed_by_researcher":null,"placed_by_institution":{"id":1,"institution_name":"Sample Institution"},"created":"2022-01-05T18:18:17.436498Z","updated":"2022-01-05T18:18:17.490612Z"}],"institution_notice":[{"notice_type":"open_to_collaborate_and_attribution_incomplete","institution":{"id":1,"institution_name":"Sample Institution"},"open_to_collaborate_img_url":"https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/ci-notice-open-to-collaborate.png","open_to_collaborate_default_text":"Our institution is committed to the development of new modes of collaboration, engagement, and partnership with Indigenous peoples for the care and stewardship of past and future heritage collections.","attribution_incomplete_img_url":"https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/ci-notice-attribution-incomplete.png","attribution_incomplete_default_text":"Collections and items in our institution have incomplete, inaccurate, and/or missing attribution. We are using this notice to clearly identify this material so that it can be updated, or corrected by communities of origin. Our institution is committed to collaboration and partnerships to address this problem of incorrect or missing attribution.","created":"2022-01-05T18:18:17.542561Z","updated":"2022-01-05T18:18:17.598332Z"}]};
  //
  // setTimeout(() => {
  //   this.parseLocalContextData(sampleData);
  // }, 2000);
}
/**
 * Labels are arranged in an array of labels for each type bc_label or tk_label.
 * Notices do not and are tagged with different values in the key: notice_type
 *
 * Labels have the following keys
 * name (string),
 * langauge_tag (string),
 * default_text (string),
 * image_url (string),
 * translations (array) - TODO: investigate array structure and render options,
 * community (string)
 *
 * Notices have the following keys
 *
 * Notice
 * bc_img_url (string),
 * bc_language_tag (string),
 * bc_default_text (string),
 * tk_img_url (string),
 * tk_default_text (string)
 *
 * Institution Notice
 * open_to_collaborate_img_url (string),
 * open_to_collaborate_default_text (string),
 * attribution_incomplete_img_url (string),
 * attribution_incomplete_default_text (string)
 *
 * Sample data
 * {
 *     "unique_id": "259854f7-b261-4c8c-8556-4b153deebc18",
 *     "title": "Sample Project",
 *     "bc_labels": [
 *         {
 *             "name": "BC Provenance (BC P) Sample Label",
 *             "label_type": "provenance",
 *             "default_text": "This SAMPLE Label is being used to affirm an inherent interest Indigenous people have in the scientific collections and data about communities, peoples, and the biodiversity found within traditional lands, waters and territories. [Community name or authorizing party] has permissioned the use of this collection and associated data for research purposes, and retains the right to be named and associated with it into the future. This association reflects a significant relationship and responsibility to [the species or biological entity] and associated scientific collections and data. This is a sample Label that is only used for example purposes.",
 *             "img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/bclabels/bc-provenance.png",
 *             "community": "Sample Community",
 *             "translations": [],
 *             "created": "2021-10-22T18:13:21.042197Z",
 *             "updated": "2021-10-22T18:14:13.252527Z"
 *         }
 *     ],
 *     "tk_labels": [
 *         {
 *             "name": "TK Creative (TK CR) Sample Label",
 *             "label_type": "creative",
 *             "default_text": "This SAMPLE Label is being used to acknowledge the relationship between the creative practices of [name] and [community name] and the associated cultural responsibilities. This is a sample Label used for examples only.",
 *             "img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/tklabels/tk-creative.png",
 *             "community": "Sample Community",
 *             "translations": [
 *                  {
 *                    "title": "TK A - Local Name",
 *                    "language": "French",
 *                    "translation": "Cette étiquette est utilisée pour corriger des erreurs historiques ou des exclusions relatives à ce matériel. Ceci est particulièrement lié aux noms des personnes impliquées dans l'exécution ou la réalisation de ce travail et/ou le nom correct de la communauté dont il provient à l'origine. En tant qu'utilisateur, il vous est également demandé d'appliquer l'attribution correcte dans toute utilisation future de ce travail."
 *                }
 *              ],
 *             "created": "2021-10-22T18:19:02.104252Z",
 *             "updated": "2021-10-22T18:25:49.578629Z"
 *         },
 *         {
 *             "name": "TK Attribution (TK A) Sample Label",
 *             "label_type": "attribution",
 *             "default_text": "This SAMPLE label is being used to correct historical mistakes or exclusions pertaining to this material. This is especially in relation to the names of the people involved in performing or making this work and/or correctly naming the community from which it originally derives. As a user you are being asked to also apply the correct attribution in any future use of this work. This is a sample Label used for example purposes only.",
 *             "img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/tklabels/tk-attribution.png",
 *             "community": "Sample Community",
 *             "translations": [],
 *             "created": "2021-10-22T18:12:04.455640Z",
 *             "updated": "2021-10-22T18:13:59.447271Z"
 *         }
 *     ]
 * }
 *
 * Sample data for Notices
 * {
 *     "unique_id": "3dbf5acc-e602-45a6-a45a-13c14edfbe8d",
 *     "title": "Sample Project with all Notices Applied",
 *     "notice": [
 *         {
 *             "notice_type": "biocultural_and_traditional_knowledge",
 *             "bc_img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/bc-notice.png",
 *             "bc_default_text": "The BC (Biocultural) Notice is a visible notification that there are accompanying cultural rights and responsibilities that need further attention for any future sharing and use of this material or data. The BC Notice recognizes the rights of Indigenous peoples to permission the use of information, collections, data and digital sequence information (DSI) generated from the biodiversity or genetic resources associated with traditional lands, waters, and territories. The BC Notice may indicate that BC Labels are in development and their implementation is being negotiated.",
 *             "tk_img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/tk-notice.png",
 *             "tk_default_text": "The TK (Traditional Knowledge) Notice is a visible notification that there are accompanying cultural rights and responsibilities that need further attention for any future sharing and use of this material. The TK Notice may indicate that TK Labels are in development and their implementation is being negotiated.",
 *             "placed_by_researcher": null,
 *             "placed_by_institution": {
 *                 "id": 1,
 *                 "institution_name": "Sample Institution"
 *             },
 *             "created": "2022-01-05T18:18:17.436498Z",
 *             "updated": "2022-01-05T18:18:17.490612Z"
 *         }
 *     ],
 *     "institution_notice": [
 *         {
 *             "notice_type": "open_to_collaborate_and_attribution_incomplete",
 *             "institution": {
 *                 "id": 1,
 *                 "institution_name": "Sample Institution"
 *             },
 *             "open_to_collaborate_img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/ci-notice-open-to-collaborate.png",
 *             "open_to_collaborate_default_text": "Our institution is committed to the development of new modes of collaboration, engagement, and partnership with Indigenous peoples for the care and stewardship of past and future heritage collections.",
 *             "attribution_incomplete_img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/ci-notice-attribution-incomplete.png",
 *             "attribution_incomplete_default_text": "Collections and items in our institution have incomplete, inaccurate, and/or missing attribution. We are using this notice to clearly identify this material so that it can be updated, or corrected by communities of origin. Our institution is committed to collaboration and partnerships to address this problem of incorrect or missing attribution.",
 *             "created": "2022-01-05T18:18:17.542561Z",
 *             "updated": "2022-01-05T18:18:17.598332Z"
 *         }
 *     ]
 * }
 */
LocalContexts.prototype.parseLocalContextData = function(json, id) {
  var self = this;
  var lcNestedKeys = ['bc_labels','tk_labels'];
  var lcFlatKeys = ['notice','institution_notice'];
  var new_json = {};

  var header_html = "";
  var expanded_html = "";

  // labels
  $.each(lcNestedKeys, function() {
    if (json[this]) {
      new_json[this] = json[this];
    }
  });

  // notices
  $.each(lcFlatKeys, function() {
    if (json[this]) {
      new_json[this] = [];
      self.fixLocalContextsNoticesJson(json[this], new_json, this);
    }
  });

  this.renderLocalContextsData(new_json, id);
}

/**
 * Assumes that the presence of an img_url key implies a default_text
 */
LocalContexts.prototype.fixLocalContextsNoticesJson = function(json, new_json, type) {
  var self = this;

  var map = {
    "bc" : "BC (Biocultural) Notice",
    "tk" : "TK (Traditional Knowledge) Notice",
    "open_to_collaborate" : "Open to Collaborate Notice",
    "attribution_incomplete" : "Attribution Incomplete Notice"
  };

  $.each(map, function(k,v) {
    if (json[0] && json[0][k + "_img_url"]) {
      new_json[type].push({
        "name" : v,
        "img_url" : json[0][k + "_img_url"],
        "default_text" : json[0][k + "_default_text"],
        "community" : self.placedBy(json[0])
      });
    }
  });

  return new_json;
}

LocalContexts.prototype.placedBy = function(json) {
  if (json['institution']) {
    return json['institution']['institution_name'];
  }

  if (json['placed_by_institution']) {
    return json['placed_by_institution']['institution_name'];
  }

  if (json['placed_by_researcher']) {
    return json['placed_by_researcher']['researcher_name'];
  }

  return '';
}

LocalContexts.prototype.renderLocalContextsData = function(new_json, id) {
  var self = this;

  var lc_data_html = "";
  var lc_img_html = "";
  var lc_img_wrapper = $('<div id="local-contexts-img-wrapper"><span id="lc-label-images-wrapper"></span><i class="fa fa-question-circle" data-toggle="tooltip" data-placement="right" title="Click an image to find out more about these Local Contexts Labels &amp; Notices."></i></div>');

  if ($('#local-contexts-img-wrapper').length == 0) {
    this.lc_img_el.after(lc_img_wrapper);
  }

  $.each(new_json, function(k,v) {
    if (v[0]) {
      var labelLanguage = v[0].language_tag;
      lc_data_html += self.renderFullDataTemplate(v[0], labelLanguage);

      if (v[0].translations && v[0].translations.length > 0) {
        lc_data_html += self.renderTranslations(v[0], labelLanguage);
      }

      if (!self.img_urls.includes(v[0].img_url)) {
        self.img_urls.push(v[0].img_url);
        lc_img_html += self.renderImageDataTemplate(v[0]);
      }
    }
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
                             .replace('${translation_title}', this.title + '&nbsp;')
                             .replace('${translation_language}', this.language)
                             .replace('${translation_translation}', this.translation);
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
                      .replace('${label_default_text}',data.default_text)
                      .replace('${label_img_url}', data.img_url)
                      .replace('${label_community}', data.community);

  return data_html;
}

LocalContexts.prototype.renderImageDataTemplate = function(data) {
  return '<img src="' + data.img_url + '" alt="' + data.name + '" class="local-contexts-header-image" />';
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
