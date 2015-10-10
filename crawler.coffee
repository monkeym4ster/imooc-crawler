#!/usr/bin/env coffee
request = require 'request'
cheerio = require 'cheerio'
fs = require 'fs'
exec = require('child_process').exec


###
# Read video list
# @param {String} URL
# @param {Function} callback
###
readVideoList = (url, callback) ->
  console.log 'Read video list: %s', url
  request.get url, (err, res) ->
    if err
      return callback(err)
    if res and res.statusCode is 200
      $ = cheerio.load(res.body)
      $('.J-media-item').each(() ->
        $me = $(this)
        item ={
          id: $me.attr('href').match(/\d+/)[0]
          name: $me.text().trim()
        }
        return callback null, item
      )

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
      return callback null, JSON.parse(res.body).data.result.mpath[0]

###
# Save video
# @param {String} url
# @param {String} filename
####
saveVideo = (url, filename) ->
  console.log 'Download video: %s', url
  request(url).pipe(
    fWriteSteam = fs.createWriteStream(filename)
  )


if process.argv.length is 3 and process.argv[2]
  url = process.argv[2]
else
  url = 'http://www.imooc.com/learn/514'
readVideoList(url, (err, video) ->
  if err
    throw err
  readVideoDetail(video.id, (err, videoUrl) ->
    if err
      throw err
    saveVideo videoUrl, video.name + '.mp4'
  )
)
