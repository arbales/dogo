LINK_DETECTION_REGEX = /(([a-z]+:\/\/)?(([a-z0-9\-]+\.)+([a-z]{2}|aero|arpa|biz|com|coop|edu|gov|info|int|jobs|mil|museum|name|nato|net|org|pro|travel))(:[0-9]{1,5})?(\/[a-z0-9_\-\.~]+)*(\/([a-z0-9_\-\.]*)(\?[a-z0-9+_\-\.%=&amp;]*)?)?(#[a-zA-Z0-9!$&'()*+.=-_~:@/?]*)?)(\s+|$)/gi

module.exports =
  randomString: (length = 3) ->
    characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
    random = ''
    for place in [0...length]
      num = Math.floor (Math.random() * characters.length)
      random += characters.substring(num, num + 1)    
    random   
  
  normalizeLink: (content) ->
    content.replace LINK_DETECTION_REGEX, (url) ->
      address = if /[a-z]+:\/\//.test url then url else "http://#{url}"