const fs = require('fs')
const showdown  = require('showdown')
const f = process.argv[2]
const h = '<!DOCTYPE html>\n<html>\n<head>\n<title>' + f + '</title>\n<meta charset="utf-8">\n<style>\n'
const css = fs.readFileSync('md.css', 'utf8')
const converter = new showdown.Converter()
const text = fs.readFileSync(f + '.md', 'utf8')
const html = converter.makeHtml(text)
fs.writeFileSync(f + '.html', h + css + '\n</style>\n' + html + '\n</body>\n</html>\n')
