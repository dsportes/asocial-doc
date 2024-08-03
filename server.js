var express = require('express');
var bodyParser = require('body-parser');
var fs = require('fs');
var app = express();
const webPush = require("web-push");

const route = '/'

/*
const keys = webPush.generateVAPIDKeys();
const VAPID_PUBLIC_KEY = keys.publicKey
const VAPID_PRIVATE_KEY = keys.privateKey
*/
const VAPID_PRIVATE_KEY = "FiRYdJ-p3UOI4CHGItM0Td9hfkc_AhJqbyz2CCw8J-M"
const VAPID_PUBLIC_KEY = "BC8J60JGGoZRHWJDrSbRih-0qi4Ug0LPbYsnft668oH56hqApUR0piwzZ_fsr0qGrkbOYSJ0lX1hPRTawQE88Ew"

// Set the keys used for encrypting the push messages.
webPush.setVapidDetails(
  "https://example.com/",
  VAPID_PUBLIC_KEY,
  VAPID_PRIVATE_KEY
);

app.use(bodyParser.json());

app.use(function maskDemoIndexes(req, res, next) {
  // Adding this redirect to simplify caching a recipe page,
  // essentially so we don't have to cache "/" and "/index.html"
  // So: "recipe/index.html" -> "recipe/" , "index.html?123" -> "?123"
  if (/\/(.*)\/index\.html\??(.*)$/.test(req.url)) {
    return res.redirect(req.url.replace('index.html', ''));
  }
  return next();
});

app.use(function setHomepageCanonical(req, res, next) {
  // Better for canonical URL, "index.html" is ugly 
  if(req.url === '/index.html') {
    return res.redirect(301, '/');
  }
  return next();
});

app.use(function forceLiveDomain(req, res, next) {
  // Don't allow user to hit Heroku now that we have a domain
  var host = req.get('Host');

  if (host === 'serviceworker-cookbook.herokuapp.com') {
    return res.redirect(301, 'https://serviceworke.rs');
  }
  return next();
});

app.use(function forceSSL(req, res, next) {
  var host = req.get('Host');
  var localhost = 'localhost';

  if (host.substring(0, localhost.length) !== localhost) {
    // https://developer.mozilla.org/en-US/docs/Web/Security/HTTP_strict_transport_security
    res.header('Strict-Transport-Security', 'max-age=15768000');
    // https://github.com/rangle/force-ssl-heroku/blob/master/force-ssl-heroku.js
    if (req.headers['x-forwarded-proto'] !== 'https') {
      return res.redirect('https://' + host + req.url);
    }
  }
  return next();
});

app.use(function corsify(req, res, next) {
  // http://enable-cors.org/server_expressjs.html
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');
  next();
});

app.use(function setServiceWorkerHeader(req, res, next) {
  // https://github.com/mozilla/serviceworker-cookbook/issues/201
  var file = req.url.split('/').pop();
  if (file === 'service-worker.js' || file === 'worker.js') {
    res.header('Cache-control', 'public, max-age=0');
  }
  next();
});

if (!fs.existsSync('./dist')) {
  throw new Error('Missing `dist` folder, execute `npm run build` first.');
}
app.use(express.static('./dist'));

app.get("/vapidPublicKey", function (req, res) {
  res.send(VAPID_PUBLIC_KEY);
});

app.post("/register", function (req, res) {
  // A real world application would store the subscription info.
  res.sendStatus(201);
});

app.post("/sendNotification", function (req, res) {
  const subscription = req.body.subscription;
  const payload = req.body.payload;
  const options = {
    TTL: req.body.ttl,
  };

  setTimeout(function () {
    webPush
      .sendNotification(subscription, payload, options)
      .then(function () {
        res.sendStatus(201);
      })
      .catch(function (error) {
        console.log(error);
        res.sendStatus(500);
      });
  }, req.body.delay * 1000);
});


var port = process.env.PORT || 3003;
var ready = new Promise(function willListen(resolve, reject) {
  app.listen(port, function didListen(err) {
    if (err) {
      reject(err);
      return;
    }
    console.log('app.listen on http://localhost:%d', port);
    resolve();
  });
});

exports.ready = ready;
exports.app = app;
