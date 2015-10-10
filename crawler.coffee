#!/usr/bin/env coffee
request = require 'request'
cheerio = require 'cheerio'
fs = require 'fs'


###
# Read video list
# @param {String} URL
# @param {Function} callback
###
readVideoList = (url, callback) ->
  console.log 'Read video list: %s', url
  request.get url, (err, res) ->
    if err
      return callback err
    if res and res.statusCode is 200
      $ = cheerio.load res.body
      $('.J-media-item').each () ->
        $me = $(this)
        item ={
          id: $me.attr('href').match(/\d+/)[0]
          name: $me.text().trim()
        }
        return callback null, item

###
# Read video detail
# @param {String} id
# @param {Function} callback
###
readVideoDetail = (id, callback) ->
  console.log 'Read video detail: %s', id
  api = 'http://www.imooc.com/course/ajaxmediainfo/?mode=flash&mid='
  request.get api + id, (err, res) ->
    if err
      return callback err
    if res and res.statusCode is 200
      body = JSON.parse(res.body)
      if body.result is 0
        return callback null, body.data.result.mpath[0]
      else
        return callback body.msg

###
# Save video
# @param {String} url
# @param {String} filename
####
saveVideo = (url, filename) ->
  console.log 'Download video %s url is %s', filename , url
  request(url).pipe(
    fs.createWriteStream filename
  )


if process.argv.length is 3 and process.argv[2]
  argv = process.argv[2]
  url = if isNaN argv then argv else 'http://www.imooc.com/learn/' + argv
else
  url = 'http://www.imooc.com/learn/514'

readVideoList url, (err, video) ->
  if err
    throw err
  readVideoDetail video.id, (err, videoUrl) ->
    if err
      throw err
    videoUrl and saveVideo videoUrl, video.name + '.mp4'
