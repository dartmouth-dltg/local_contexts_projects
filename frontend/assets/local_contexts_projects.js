/* local_context/frontend/assets/local_context.js */
class LocalContexts {
  constructor(type = "multi") {
    this.frontendPrefix = LOCALCONTEXTS_FRONTEND_PREFIX;
    this.lc_data_el = $('#local-contexts-data-holder');
    this.fetch_type = type;
    this.mainLanguage = typeof($('html').attr('lang')) !== 'undefined' ? $('html').attr('lang') : '';
    this.setupLocalContextsAction();
  }

  setupLocalContextsAction() {
    const self = this;

    $('#fetch-local-contexts-data').click( function() {
      $(this).addClass('fetching');
      self.lc_data_el.html('');
      if (self.fetch_type == "single") {
        const projectId = $(this).closest('.record-pane').find('label[for=local_contexts_project_project_id_]').siblings('div.label-only').text();
        self.fetchLocalContextData(projectId, $(this))
      }
      else {
        const projectIdsClass = $(this).closest('section').find('[class*=local-contexts-project-id]');
        const btn = $(this);
        $.each(projectIdsClass, function() {
          const projectId = $(this).attr("class").match(/local-contexts-project-id-(.*)/i)[1];
          if (projectId) {
            self.fetchLocalContextData(projectId, btn)
          }
        });
      }
    });
  }

  fetchLocalContextData(id, btn) {
    const self = this;

    $.ajax({
      url: self.frontendPrefix + "plugins/local_contexts_projects/fetch_lc_project_data",
      data: {
        project_id: id,
        use_cache: true
      },
      dataType: 'json'
    })
    .done( function(data) {
      if (data !== null && data['unique_id'] == id) {
        self.parseLocalContextsData(data, id);
      }
      else {
        self.renderLocalContextsError(id);
      }
      btn.removeClass('fetching');
    })
    .fail( function() {
      self.renderLocalContextsError(id);
      btn.removeClass('fetching');
    });
  }
  /**
   * Labels are arranged in an array of labels for each type bc_label or tk_label.
   *
   * Labels have the following keys
   * name (string),
   * language_tag (string),
   * label_text (string),
   * image_url (string),
   * translations (array) - TODO: investigate array structure and render options,
   * community (string)
   *
   * Notices have the following keys
   *
   * Notice
   * img_url (string),
   * default_text (string)
   *
   * Institution Notice
   * img_url (string),
   * default_text (string),
   *
   * Sample data
   * {
   *     "unique_id": "259854f7-b261-4c8c-8556-4b153deebc18",
   *     "title": "Sample Project",
   *     "bc_labels": [
   *         {
   *             "name": "BC Provenance (BC P) Sample Label",
   *             "label_type": "provenance",
   *             "label_text": "This SAMPLE Label is being used to affirm an inherent interest Indigenous people have in the scientific collections and data about communities, peoples, and the biodiversity found within traditional lands, waters and territories. [Community name or authorizing party] has permissioned the use of this collection and associated data for research purposes, and retains the right to be named and associated with it into the future. This association reflects a significant relationship and responsibility to [the species or biological entity] and associated scientific collections and data. This is a sample Label that is only used for example purposes.",
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
   *             "label_text": "This SAMPLE Label is being used to acknowledge the relationship between the creative practices of [name] and [community name] and the associated cultural responsibilities. This is a sample Label used for examples only.",
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
   *             "label_text": "This SAMPLE label is being used to correct historical mistakes or exclusions pertaining to this material. This is especially in relation to the names of the people involved in performing or making this work and/or correctly naming the community from which it originally derives. As a user you are being asked to also apply the correct attribution in any future use of this work. This is a sample Label used for example purposes only.",
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
   *     "created": [
   *          {
   *              "institution": {
   *                 "id": 1,
   *                 "institution_name": "Sample Institution"
   *             },
   *          }
   *     ],
   *     "notice": [
   *         {
   *             "notice_type": "biocultural",
   *             "img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/bc-notice.png",
   *             "default_text": "The BC (Biocultural) Notice is a visible notification that there are accompanying cultural rights and responsibilities that need further attention for any future sharing and use of this material or data. The BC Notice recognizes the rights of Indigenous peoples to permission the use of information, collections, data and digital sequence information (DSI) generated from the biodiversity or genetic resources associated with traditional lands, waters, and territories. The BC Notice may indicate that BC Labels are in development and their implementation is being negotiated.",
   *             "researcher": null,
   *             "institution": {
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
   *             "img_url": "https://storage.googleapis.com/anth-ja77-local-contexts-8985.appspot.com/labels/notices/ci-notice-open-to-collaborate.png",
   *             "default_text": "Our institution is committed to the development of new modes of collaboration, engagement, and partnership with Indigenous peoples for the care and stewardship of past and future heritage collections.",
   *             "created": "2022-01-05T18:18:17.542561Z",
   *             "updated": "2022-01-05T18:18:17.598332Z"
   *         }
   *     ]
   * }
   */
  parseLocalContextsData(json, id) {
    const self = this;
    const lcNestedKeys = ['bc_labels','tk_labels','notice'];
    let new_json = {};

    // labels
    $.each(lcNestedKeys, function() {
      if (json[this]) {
        new_json[this] = json[this];
      }
    });

    this.renderLocalContextsData(new_json, json, id);
  }

  renderLocalContextsData(new_json, json, id) {
    const self = this;
    let lc_data_html = '<div class="lc-project-data-label">Project Id: <b>' + id + '</b><br /> Local Contexts Hub Project Name: <b>' + json.title + '</b></div>';

    $.each(new_json, function(k,v) {
      $.each(v, function(idx, label) {
        if (typeof(label.default_text) !== 'undefined' && k == 'notice') {
          label['label_text'] = label.default_text;
        }
        lc_data_html += AS.renderTemplate("template_local_context_data", {label: label, id: id, main_language: this.main_language});
      })
    });

    this.lc_data_el.append(lc_data_html);
    this.lc_data_el.append('<div><span class="btn btn-sm btn-primary show-lc-json">Hide/Show JSON data for this project</span></div><pre class="lc-json">' + JSON.stringify(json, undefined, 2) + '</pre>');

  }

  renderLocalContextsError(id) {
    const self = this;

    const target_el = $('#local-contexts-data-holder');
    const error_msg = AS.renderTemplate("template_local_context_error", {id: id});
    this.lc_data_el.append(error_msg);
  }
}

class ResetLocalContextsCache {
  constructor(interactive = true) {
    this.frontendPrefix = LOCALCONTEXTS_FRONTEND_PREFIX;
    this.use_otc = USE_OPEN_TO_COLLABORATE;
    if (interactive) {
      this.loadResetCacheModal();
    }
  }

  loadResetCacheModal() {
    const self = this;

    let project_ids = [];
    $('#tabledSearchResults td.sortable').each(function() {
      const p_id = $(this).text().split(":")[0].trim();
      const p_title = $(this).text().split(":")[1].trim()
      project_ids.push({"id" : p_id, "title" : p_title});
    });

    const $modal = AS.openCustomModal("quickModal",
      AS.renderTemplate("template_local_context_reset_cache_title"),
      AS.renderTemplate("modal_quick_template", {
        message: AS.renderTemplate("template_local_context_reset_cache_contents", {
          project_ids: project_ids,
          open_to_collaborate: self.use_otc
        })
      }),
      "full");

    $modal.find(".modal-footer").replaceWith(AS.renderTemplate("template_local_context_reset_cache_footer"));

    self.bindLocalContextsCacheResetEvents($modal);
  }

  bindLocalContextsCacheResetEvents($container) {
    const self = this;

    $container.
      on("click", ".reset-local-contexts-cache-btn", function(event) {
        event.preventDefault();
        const pid = $(this).children('a').attr('id');
        const lc_type = pid == 'open_to_collaborate' ? pid : 'project';
        self.setupResetCacheForProject(pid, lc_type, $(this));
      });
  }

  setupResetCacheForProject(pid, lc_type, btn) {
    const self = this;

    let msg = '';
    btn.addClass('fetching');
    const successMsg = AS.renderTemplate("template_local_context_reset_cache_success")
    const errorMsg = AS.renderTemplate("template_local_context_reset_cache_error")
    $.when(this.resetCacheForProject(pid, lc_type))
      .done( function(data) {
        if (pid == lc_type) {
          if (!data.notice_type || data.notice_type != pid) {
            msg = errorMsg
          }
          else {
            msg = successMsg
          }
        }
        else {
          if (!data.unique_id || data.unique_id != pid) {
            msg = errorMsg
          }
          else {
            msg = successMsg
          }
        }
        $('#'+pid).parent('button').siblings('.local-contexts-pid').append(msg)
        btn.removeClass('fetching');
      })
      .fail( function() {
        btn.removeClass('fetching');
      });
  }

  resetCacheForProject(pid, lc_type) {
    const self = this;
    return $.ajax({
      url: self.frontendPrefix + "plugins/local_contexts_projects/reset_cache",
      method: 'POST',
      data: {
        project_id: pid,
        type: lc_type
      },
      dataType: 'json'
    })
  }
}

$().ready( function() {
  // toggle json
  $('body').on('click', '.show-lc-json', function() {
    const json_container = $(this).parent('div').next('pre');
    if (json_container.hasClass('shown')) {
      json_container.removeClass('shown');
    }
    else json_container.addClass("shown");
  });

  // toggle translations
  $('body').on('click', '.local-contexts-translation-toggle', function() {
    const translation_container = $(this).siblings('.local-contexts-translation-wrapper');

    if (translation_container.hasClass('shown')) {
      translation_container.removeClass('shown');
    }

    else translation_container.addClass("shown");
  });

  // reset cache setup
  $('body').on('click', '.local-contexts-manage-cache-btn', function(evt) {
    evt.preventDefault();
    new ResetLocalContextsCache(true);
  });
});
