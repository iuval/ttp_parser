require 'rubygems'
require 'nokogiri'
require 'debugger'
require 'json'

page = Nokogiri::HTML(open('html/clean.html'))
puts page.class   # => Nokogiri::HTML::Document

def fix_text(str)
  str.delete("\n").strip.squeeze
end

class Example
  attr_accessor :number, :content, :solution, :answer

  def initialize
    @content = ""
    @solution = ""
    @answer = ""
  end
end

class Lesson
  attr_accessor :number, :name, :content, :examples

  def initialize
    @name = ""
    @content = ""
    @examples = []
  end
end

class Chapter
  attr_accessor :number, :name, :content, :lessons, :examples

  def initialize
    @content = ''
    @name = ''
    @lessons = []
    @examples = []
  end
end

chapters = []
chapter = nil
lesson = nil
current_elem = nil
current_example = nil
next_is_solution = false;
page.text.lines.each do |text|
  text = fix_text text
  unless text.empty?
    match = text.match /Solution:/ # example number
    if match
      next_is_solution = true;
    else
      match = text.match /Answer: (\d*)/ # example number
      if match
        next_is_solution = false;
        current_example.answer = match[0]
        current_example = nil
      else
        match = text.match /Example (\d+):/ # example number
        if match
          example = Example.new
          example.number = match[1]
          current_elem.examples.push example
          current_example = example
        else
          match = text.match /(\d+.\d+):(.*)/ # chapter nubmer ie:10.5
          if match
            chapter = Chapter.new
            chapter.number = match[1]
            chapter.name = match[2]
            chapters.push chapter
            current_elem = chapter
          else
            match = text.match /^(\d(?:.(?:\d)+)+\))(.*)/ # lesson number ie: 10.5.2
            if match
              lesson = Lesson.new
              lesson.number = match[1]
              lesson.name = match[2]
              chapter.lessons.push lesson
              current_elem = lesson
            else
              if current_example
                if next_is_solution
                  current_example.solution = current_example.solution + text
                else
                  current_example.content = current_example.content + text
                end
              elsif current_elem
                current_elem.content = current_elem.content + text
              end
            end
          end
        end
      end
    end
  end
  match = nil
end

json = []
# generate markdown
chapters.each do |c|
  chapt_examples = []
  c.examples.each do |e|
    examp = { number: e.number,
              content: e.content,
              solution: e.solution }
    chapt_examples.push examp
  end
  chapt_lessons = []
  c.lessons.each do |l|
    lesson_examples = []
    l.examples.each do |e|
      examp = { number: e.number,
                content: e.content,
                solution: e.solution }
      lesson_examples.push examp
    end
    lesson = { number: c.number,
               name: c.name,
               content: c.content,
               examples: lesson_examples }
    chapt_lessons.push lesson
  end
  chapt = { number: c.number,
            name: c.name,
            content: c.content,
            examples: chapt_examples,
            lessons: chapt_lessons }
  json.push chapt
end

puts JSON.pretty_generate(json)