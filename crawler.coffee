#!/usr/bin/env coffee
request = require('request')
cheerio = require('cheerio')
fs = require('fs')
colors = require('colors')

website = 'http://www.imooc.com'

###
# Read video list
# @param {String} URL
# @param {Function} callback
###
readVideoList = (url, callback) ->
  console.log colors.gray "Read video list: #{url}"
  request.get url, (err, res) ->
    if err
      return callback err
    if res and res.statusCode is 200
      $ = cheerio.load(res.body)
      videos = []
      $('.J-media-item').each () ->
        $me = $(this)
        item = {
          id: $me.attr('href').match(/\d+/)[0]
          name: $me.text().trim()
        }
        videos.push item
      return callback null, videos
    return
  return

###
# Read video detail
# @param {Object} video
# @param {Function} callback
###
readVideoDetailAndDownload = (video, callback) ->
  api = website + '/course/ajaxmediainfo/?mode=flash&mid='
  url = api + video.id
  console.log colors.gray "Read video detail and download: #{video.name}.mp4 , url: #{url}"
  request.get url, (err, res) ->
    if err
      return callback err
    if res and res.statusCode is 200
      body = JSON.parse(res.body)
      if body.result is 0
        filename = video.name.replace(/([\\\/\:\*\?\"\<\>\|])/g,'_') + '.mp4'
        request(body.data.result.mpath[0]).pipe(fs.createWriteStream(filename))
      else
        return callback body.msg
    return
  return

###
# Read course list
# @param {String} url
# @param {Function} callback
###
readCourseList = (url, callback) ->
  console.log colors.gray "Read course list: #{url}"
  request url, (err, res) ->
    if err
      return callback(err)
    if res and res.statusCode is 200
      $ = cheerio.load(res.body)
      courses = []
      courseItem = $('.course-item')
      courseItem.each(() ->
        $me = $(this)
        item = {
          title: $me.find('.title').text().trim()
          description: $me.find('.description').text().trim()
          url: website + $me.find('a').attr('href')
        }
        courses.push item
      )
      nextPage = $('.page').find('.active').next().attr('data-page')
      if not nextPage
        return callback(null, courses)
      nextPageURL = url.replace(/(\d+$)/, nextPage)
      readCourseList nextPageURL, (err, courses2) ->
        if err
          return callback(err)
        return callback(null, courses.concat(courses2))
    return
  return

###
# Search course
# @param {String} words
# @param {Function} callback
###
searchCourse = (words, callback) ->
  url = website + '/index/search?words=' + words + '&page=1'
  request url, (err, res) ->
    if err
      return callback(err)
    if res and res.statusCode is 200
      $ = cheerio.load(res.body)
      courseItem = $('.course-item')
      if not courseItem.length
        return callback("There is no result on \"#{words}\".")
      readCourseList(url, callback)
    return
  return

###
# Do work
# @param {String} action
# @param {String} value
# @param {Function} callback
###
doWork = (action, value, callback) ->
  switch action
    when '--search'
      if not value
        return callback 'Please input keywords.'
      return searchCourse(value, callback)
    when '--list'
      if not value
        return callback 'Please input course URL or ID'
      url = if isNaN value then value else website + '/learn/' + value
      return readVideoList(url, callback)
    when '--download'
      if not value
        return callback 'Please input course URL or ID'
      url = if isNaN value then value else website + '/learn/' + value
      readVideoList url, (err, video) ->
        if err
          return callback err
        return readVideoDetailAndDownload video, callback
      return
    else
      return callback 'Unknown action.'

argv = process.argv.slice(2)

if not argv[0]
  console.log "Usage: crawler.coffee [Options]"
  console.log "  --search\t Search for the specified keywords"
  console.log "  --list\t List the video list under the specified course ID or URL"
  console.log "  --download\t Download the video list under the specified course ID or URL"
  return

for arg of argv
  if arg % 2 isnt 0
    continue
  action = argv[arg]
  value = argv[Number(arg) + 1]
  doWork action, value, (err, res) ->
    if err
      return console.error colors.red(err)
    for arr in res
      console.log '-'.repeat(30)
      for key of arr
        val = arr[key]
        console.log "#{colors.green(key)}: #{val}"
    return
