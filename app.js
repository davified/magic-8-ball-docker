'use strict'

const express = require('express')

// Constants
const PORT = 8080 || process.env.PORT

// App
const app = express()
const messages = ['Signs point to yes.',
  'Yes.',
  'Reply hazy',
  'Try again.',
  'Without a doubt.',
  'My sources say no.',
  'As I see it',
  'Yes.',
  'You may rely on it.',
  'Concentrate and ask again.',
  'Outlook not so good.',
  'It is decidedly so.',
  'Better not tell you now.',
  'Very doubtful.',
  'Yes - definitely.',
  'It is certain.',
  'Cannot predict now.',
  'Most likely.',
  'Ask again later.',
  'My reply is no.',
  'Outlook good.',
  "Don't count on it."
]

app.get('/',
 function (req, res) {
	 let randomInt = getRandomInt(0, messages.length)
   res.json({'Magic 8 ball says': messages[randomInt]})
 })

app.listen(PORT)
console.log('Running on port ' + PORT)

function getRandomInt (min, max) {
  return Math.floor(Math.random() * (max - min)) + min
}
