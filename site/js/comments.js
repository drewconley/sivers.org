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
      html += ' (' + c.created_at + ') <a href="#' + id + '">#</a></cite>';
      html += '<p>' + formatComment(c.html) + '</p>';
      li.innerHTML = html;
      ol.appendChild(li);
    }
    return ol;
  }
  
  var isLoaded = false;
  function showComments() {
    if(isLoaded === false) {
      var commentSection = document.getElementById('comments');
      commentSection.innerHTML = '<header><h1>Your thoughts? Please leave a reply:</h1><form action="/comments" method="post"><label for="name_field">Your Name</label><input type="text" name="name" id="name_field" value="" /><label for="email_field">Your Email &nbsp; <span class="small">(private for my eyes only)</span></label><input type="email" name="email" id="email_field" value="" /><label for="url_field">Your Website</label><input type="text" name="url" id="url_field" value="" /><label for="comment">Comment</label><textarea name="comment" id="comment" cols="35" rows="10"></textarea><br /><input name="submit" type="submit" class="submit" value="submit comment" /></form></header><h1>Comments</h1>';
      var ol = commentsToHTML(getComments(location.pathname));
      if(ol) {
	commentSection.appendChild(ol);
      }
      isLoaded = true;
    }
  }
  
  function weHitBottom() {
    var contentHeight = document.getElementById('content').offsetHeight;
    var y1 = (window.pageYOffset !== undefined) ? window.pageYOffset : (document.documentElement || document.body.parentNode || document.body).scrollTop;
    var y2 = (window.innerHeight !== undefined) ? window.innerHeight : document.documentElement.clientHeight;
    var y = y1 + y2;
    if (y >= contentHeight) {
      showComments();
    }
  }

  // check for bottom now
  weHitBottom();

  // check again when scrolling
  if(isLoaded === false) {
    window.onscroll = weHitBottom;
  }

  // if URL has #comment-12345 then show comments immediately
  if(/comment-\d+/.test(location.hash)) {
    showComments();
  }
  
})();

