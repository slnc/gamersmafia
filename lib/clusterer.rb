#--
###Copyright (c) 2006 Surendra K Singhi <ssinghi AT kreeti DOT com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


module Clusterer
  VERSION = '0.2.0'
end

require 'clusterer/stop_words'
require 'clusterer/similarity'
require 'clusterer/tokenizer'
require 'clusterer/document_base'
require 'clusterer/inverse_document_frequency'
require 'clusterer/document'
require 'clusterer/documents_centroid'
require 'clusterer/document_array'
require 'clusterer/cluster'
require 'clusterer/algorithms'
require 'clusterer/clustering'
require 'clusterer/lsi/lsi'
require 'clusterer/bayes'


class Foo
  def initialize(title, bbody=nil)
    @title = title
    @body = bbody ? bbody : ''
  end

  def title
    @title
  end

  def snippet
    @body
  end

  def body
    @body
  end
end


def proc_for_clustering(input)
  newstr = input.clone
  newstr.gsub!('á', 'a')
  newstr.gsub!("\r\n", " ")
  newstr.gsub!("\n", " ")
  newstr.gsub!('é', 'e')
  newstr.gsub!('í', 'i')
  newstr.gsub!('ó', 'o')
  newstr.gsub!('ú', 'u')
  newstr.gsub!('Á', 'A')
  newstr.gsub!('É', 'E')
  newstr.gsub!('Í', 'I')
  newstr.gsub!('Ó', 'O')
  newstr.gsub!('Ú', 'U')
  newstr.gsub!('ñ', 'n')
  newstr.gsub!('Ñ', 'n')
  newstr.gsub!(/<\/?[^>]*>/, "")
  newstr.gsub!(/(#[0-9]+)/, "")
  newstr.gsub!(/\[\/?[^\]*]/, "")
  newstr.gsub!(Cms::URL_REGEXP, "")
  newstr
end

def write_cluster_results(clusters, fname="temp1b.html")
  File.open(fname,"w") do |f|
    f.write("<ul>")
    clusters.each do |clus|
      f.write("<li>")
      f.write("<h4>")
      clus.centroid.to_a.sort{|a,b| b[1] <=> a[1]}.slice(0,5).each {|w| f.write("#{w[0]} - #{format '%.2f',w[1]}, ")}
      f.write("</h4>")
      #f.write("<ul>")
      #clus.documents.each do |doc|
        #result = doc.object
        #f.write("<li>")
        #f.write("<span class='title'>")
        #f.write(result.title)
        #f.write("</span>")
        #f.write("<span class='snippet'>")
        #f.write(result.snippet)
        #f.write("</span>")
        #f.write("</li>")
      #end
      #f.write("</ul>")
    end
    #f.write("</ul>")
    f.write("</li>")
  end
end
