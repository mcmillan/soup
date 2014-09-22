async   = require('async')
cache   = require('memory-cache')
cheerio = require('cheerio')
request = require('request')
app     = require('express')()

class SoupScraper
  @pret: (callback) ->
    return callback(null, soups) if soups = cache.get('soups.pret')

    request 'http://www.pret.com/todays_soups.htm', (err, response) ->
      return callback(err) if err

      soups = []
      $     = cheerio.load(response.body)

      $('#flowpanes .panel.soup ul li a img').each ->
        soups.push($(this).attr('alt').trim())

      cache.put('soups.pret', soups, 30000)

      callback(null, soups)

  @eat: (callback) ->
    return callback(null, soups) if soups = cache.get('soups.eat')

    request 'http://eat.co.uk/', (err, response) ->
      return callback(err) if err

      soups = []
      $     = cheerio.load(response.body)

      $('.specials-content.bg-primary .listing-tile h4').each ->
        soups.push($(this).text().replace(/\s+/g, ' ').trim())

      cache.put('soups.eat', soups, 30000)

      callback(null, soups)

  @all: (callback) ->
    async.parallel(pret: @pret, eat: @eat, callback)

app.get '/', (req, res) ->
  SoupScraper.all (err, soups) -> res.send(soups)

app.get '/pret', (req, res) ->
  SoupScraper.pret (err, soups) -> res.send(soups)

app.get '/eat', (req, res) ->
  SoupScraper.eat (err, soups) ->  res.send(soups)

app.listen(process.env.PORT or 1337)
