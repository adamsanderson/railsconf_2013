#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'redcarpet'

DIVIDER = /^---\s*$/

@markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, 
  autolink: true,
  tables: true,
  fenced_code_blocks: true
)

template_path = "./template.html"
output_path   = "./index.html"
slides_path   = "./slides.markdown"

def header(text)
  render(text, "header", "caption")
end

def slide(text)
  render(text, "section", "slide")
end

def render(text, tag='section', cls='slide')
  "<#{tag} class='#{cls}'><div>\n" + @markdown.render(text) + "\n</div></#{tag}>\n\n"
end

template = IO.read(template_path)
slides   = IO.read(slides_path).split(DIVIDER)
html     = header(slides.shift)

slides.each do |text|
  html << slide(text)
end

open(output_path, "w") do |io|
  io << template.sub('<!-- SLIDES -->', html)  
end