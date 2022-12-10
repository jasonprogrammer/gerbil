import hljs from 'highlight.js';

import javascript from 'highlight.js/lib/languages/javascript';
hljs.registerLanguage('javascript', javascript);

import python from 'highlight.js/lib/languages/python';
hljs.registerLanguage('python', python);

import nim from 'highlight.js/lib/languages/nim';
hljs.registerLanguage('nim', nim);

import shell from 'highlight.js/lib/languages/shell';
hljs.registerLanguage('shell', shell);

import json from 'highlight.js/lib/languages/json';
hljs.registerLanguage('json', json);

import xml from 'highlight.js/lib/languages/xml';
hljs.registerLanguage('xml', xml);

import lisp from 'highlight.js/lib/languages/lisp';
hljs.registerLanguage('lisp', lisp);

import css from 'highlight.js/lib/languages/css';
hljs.registerLanguage('css', css);


import 'highlight.js/styles/github.css';

import $ from "cash-dom";
const axios = require('axios');
axios.defaults.headers.post['Content-Type'] = 'application/json';

function submitComment() {
    $('#spam-fail').hide();

    let $outer = $('#st-content-outer')
    let contentID = $outer.attr('data-content-id')
    let podName = $outer.attr('data-pod-name')
    axios.post(`/content/${podName}/${contentID}/comment`, {
        text: $('#comment-submit-ta').val(),
        encryptedAnswer: $('#spam-container').attr('data-spam-answer'),
        answer: $('#answer').val()
      })
      .then(function (response) {
          if(response.status == 201) {
              $('#comment-form').hide();
              $('#comment-success').show();
          }
      })
      .catch(function (error) {
          if(error.response.status == 403) {
              $('#spam-fail').show();
          }
      })
}

$(function () {
    document.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightBlock(block);
    });

    $('#comment-submit-btn').on('click', function() {
        submitComment();
    })

    $('#answer').on('keypress', function(e) {
        if(e.which == 13) {
            submitComment();
        }
    })
});
