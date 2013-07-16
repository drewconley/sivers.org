(function() {
function getComments(pp, id) {
  if(pp !== 'post' && pp !== 'presentation') { return false; }
  if(/\D/.test(id)) { return false; }
  var comments = [];
  try {
    var xhr = new XMLHttpRequest();
    xhr.open('get', '/comments/' + pp + '/' + id + '.json', false);
    xhr.send(null);
    if(xhr.status == 200) {
      comments = JSON.parse(xhr.responseText);
    }
  } catch(e) { }
  return comments;
}

function formatComment(txt) {
  var re = /\s((https?):\/\/\S+)/gim;
  txt = txt.replace(re, ' <a href="$1">$1</a> ');
  txt = txt.replace(/\n/g, '<br>');
  return txt;
}

function commentsToHTML(comments) {
  var len = comments.length;
  if(len === 0) { return false; }
  var ol = document.createElement('ol');
  for(var i = 0; i < len; i++) {
    var c = comments[i];
    var id = 'comment-' + c.id;
    var li = document.createElement('li');
    li.id = id;
    var html = '<cite>';
    if(c.url && c.url.length > 0) { html += '<a href="' + c.url + '">'; }
    html += c.name;
    if(c.url && c.url.length > 0) { html += '</a>'; }
    html += ' (' + c.date + ') <a href="#' + id + '">#</a></cite>';
    html += '<p>' + formatComment(c.comment) + '</p>';
    li.innerHTML = html;
    ol.appendChild(li);
  }
  return ol;
}

// infinite scrolling: https://github.com/alexblack/infinite-scroll
function infiniteScroll(options) {
  var scroller = { options: options, updateInitiated: false };
  window.onscroll = function(event) {
    handleScroll(scroller, event);
  };
  document.ontouchmove = function(event) {
    handleScroll(scroller, event);
  };
}

function getScrollPos() {
  if (document.documentElement && document.documentElement.scrollTop) {
    return document.documentElement.scrollTop;
  } else {
    return window.pageYOffset;
  }
}

var prevScrollPos = getScrollPos();
function handleScroll(scroller, event) {
  if (scroller.updateInitiated) { return; }   
  var scrollPos = getScrollPos();
  if (scrollPos == prevScrollPos) { return; }
  var pageHeight = document.documentElement.scrollHeight;
  var clientHeight = document.documentElement.clientHeight;
  if (pageHeight - (scrollPos + clientHeight) < scroller.options.distance) {
    scroller.updateInitiated = true;
    scroller.options.callback(function() {
      scroller.updateInitiated = false;
    });
  }
  prevScrollPos = scrollPos;  
}
//  END infiniteScroll stuff

var isLoaded = false;

function showComments() {
  // There's either <h1 id="post-1234"> or <h1 id="presentation-1234"> inside <section id="maintitle">
  var m = /(post|presentation)-(\d+)/.exec(document.getElementById('maintitle').querySelector('h1').id);
  document.getElementById('comments').appendChild(commentsToHTML(getComments(m[1], m[2])));
  isLoaded = true;
}

// if URL has #comment-21084 then show comments immediately
if(/comment-\d+/.test(location.hash)) {
  showComments();
}

var nowShowComments = function(done) {
  if(isLoaded === false) {
    showComments();
  }
  done();
};

infiniteScroll({ distance: 50, callback: nowShowComments });
})();

