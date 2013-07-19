(function() {
  function getComments(uri) {
    var comments = [];
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('get', '/comments' + uri + '.json', false);
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
    var len, ol, i, c, id, li, html;
    len = comments.length;
    if(len === 0) { return false; }
    ol = document.createElement('ol');
    for(i = 0; i < len; i++) {
      c = comments[i];
      id = 'comment-' + c.id;
      li = document.createElement('li');
      li.id = id;
      html = '<cite>';
      if(c.url && c.url.length > 0) { html += '<a href="' + c.url + '">'; }
      html += c.name;
      if(c.url && c.url.length > 0) { html += '</a>'; }
      html += ' (' + c.date + ') <a href="#' + id + '">#</a></cite>';
      html += '<p>' + formatComment(c.html) + '</p>';
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
    var ol = commentsToHTML(getComments(location.pathname));
    if(ol) {
      document.getElementById('comments').appendChild(ol);
    }
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

