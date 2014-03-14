require 'ostruct'
require 'pp'
$attempt = 0
$passed = 0
class HWElement < OpenStruct
	def subelements
		[]
	end

	def random_str(size)
		o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
		string = (0...size).map { o[$prng.rand(o.length)] }.join
	end

	def generate
		raise 'Each element should implement the generate function.'
	end

	def assert_score(msg, msg_pass, msg_fail, &cond)
		$attempt = $attempt + 1
		pass = false

		begin
			pass = cond.call
		rescue Exception => e
			puts e.message
			puts e.backtrace.inspect
			pass = false
		end

		if pass == true
			puts "#{$attempt}. [#{msg}] Passed : #{msg_pass}"
			$passed = $passed + 1
		else
			puts "#{$attempt}. [#{msg}] Failed : #{msg_fail}"
		end
		pass
	end

	def verifyr(browser)
		begin 
			nb = verify(browser) #verify current element

			if nb.respond_to?(:browser)
				brow = nb
			else
				brow = browser
			end

			@saved_subelements.each{ |sel|
				sel.verifyr(brow)
			}
		rescue Exception => e
			puts "Nu s-a putut verifica elementul #{name} datorita urmatoarei exceptii: #{e.message}."
		end
	end

	def verify(browser)
		raise 'Each element should implement the verify function'
	end

	def properties
		{}
	end
	
	def gen_tabs(num)
		tabs = ""
		num.times { tabs << "\t" }
		tabs
	end
	def generate_description(level = 0)
		tabs = gen_tabs(level)
		@saved_subelements = subelements
		subelem_gen = @saved_subelements.map{|elem| elem.generate_description(level+1)}.join("\n")
		props = tabs + generate.join("\n" + tabs) + "\n"
		description = "#{tabs}#{name}: \n#{tabs}Acest element va avea urmatoarele proprietati:\n#{props}"
		description += "#{tabs}si urmatoarele subelemente: \n" + subelem_gen if subelements.size > 0
		description
	end
	
	def rtf
		($prng.rand(1..2) == 1 ? true : false)
	end

	def initialize(props = properties)
		super(props)
	end
end

class HTMLPage < HWElement
	def verify(b)
		puts "Se verifica pagina #{filename}"
		file_path = "#{File.dirname(__FILE__)}/#{filename}"
		
		if (filename == "index.html") 
			puts "Se elimina tag-urile <blockquote> pentru a se putea incarca corect pagina in browser."
			contents = (f = File.new(file_path)).read
			f.close
			contents.gsub!(/<blockquote.*?>/,"")
			contents.gsub!("</blockquote>", "")
			f = File.new(file_path, "w")
			f.write(contents)
			f.close
		end

		assert_score("Verificare Existenta Pagina", "Pagina este prezenta", "Pagina #{file_path} nu exista pe disk") { File.exists?(file_path) }
		
		b.goto "file://#{file_path}"
		
		assert_score("Verificare Titlul Pagina", "Titlul este corect", "Titlul este incorect, trebuie sa contina #{title}") { b.title.include?(title) }
		
		keywords = b.meta(:name=>"keywords")
		assert_score("Verificare Existenta Meta Keywords", "Tag-ul meta exista", "Nu exista nici un tag meta cu name=\"keywords\"") { keywords!=null }
		
		keywords_value = keywords.attribute_value("content")
		assert_score("Verificare existenta attribut content pentru tagul meta", "OK", "Not OK") { keywords_value!=nil }

		meta_vals = meta_keywords.split(",").map{|k| k.strip }
		meta_vals.each{ |v|
			assert_score("Verificare keyword #{v}", "OK", "Keyword-ul #{v} nu e prezent.") { keywords_value.include?(v) }
		}
	end

	def generate
		[
			"Numele fisierului HTML: #{filename}",
			"Titlul paginii : #{title}",
			"Meta Keywords : #{meta_keywords}"
		]	
	end
end

class Div < HWElement
	def verify(b)
		assert_score("Verificare existenta div #{id}", "OK", "Not OK") {
			b.div(:id => id).exists?
		}
		b.div(:id => id)
	end

	def generate
		[
			"ID : #{id}"
		]
	end

	def properties
		{
			:name => "div (Articol Text)",
			:id => random_str(10)
		}
	end
end

class ArticleDate < HWElement
	def verify(b)
		assert_score("Verificare existenta div data", "OK", "Nu exista div-ul pentru data cu id-ul #{id}") { b.div(:id => id).exists? }
		assert_score("Verificare Data", "Data este corecta", "Data incorecta, se astepta #{data.to_s}") { b.div(:id => id).text.include?(date.to_s) }
	end

	def generate
		[
			"ID : #{id}",
			"Data : #{date.to_s}"
		]
	end
	def properties
		{
			:name => "Data Articol (div)",
			:id => random_str(10),
			:date => Time.at(123456789+$prng.rand(10000000))
		}
	end
end

class Text < HWElement
	def count_words(text)
		text.gsub(/[.,;:'"\(\)]/," ").gsub(/\s+/," ").split(" ").size
	end

	def verify(b)
		assert_score("Verificare existenta element paragraf", "OK", "Nu exista nici un paragraf") { b.p.exists? }
		assert_score("Verificare tag cite pentru #{cite ? 'prezenta' : 'absenta'}", "OK", "Not OK") { b.p.cite.exists? == cite }
		assert_score("Verificare numar de cuvinte", "OK", "Numarul de cuvinte identificate(#{count_words(b.p.text)} nu este egal cu cel din cerinta (#{num_words})") { num_words == count_words(b.p.text) }
		assert_score("Verificare tag sup pentru #{sup ? 'prezenta' : 'absenta'}", "OK", "Not OK") { b.p.sup.exists? == sup }
		assert_score("Verificare tag sub pentru #{sub ? 'prezenta' : 'absenta'}", "OK", "Not OK") { b.p.sub.exists? == sub }
		assert_score("Punctare cerinta invalida blockquote", "OK","") { true }
	end
	def generate
		[
			"Numar de cuvinte: #{num_words}",
			"Trebuie sa contina tag-uri blockquote : #{blockquote}",
			"Trebuie sa contina tag-uri cite: #{cite}",
			"Trebuie sa contina tag-uri super: #{sup}",
			"Trebuie sa contina tag-uri sub: #{sub}"
		]
	end
	def properties
		{
			:name => "Paragraf text (p)",
			:num_words => $prng.rand(10..50),
			:blockquote => rtf,
			:cite => rtf,
			:sup => rtf,
			:sub => rtf
		}
	end
end

class Image < HWElement
	def img_ext(src)
		s = src.split(".")
		s[s.size-1].upcase
	end

	def verify(b)
		loaded = false
		assert_score("Verificare existenta imagine de tip #{img_type} cu dimensiunile #{width}x#{height} si text alternativ #{alt_text}", "OK", "Not OK") {
			exists = false
			b.imgs.each { |img|
				ext=img_ext(img.attribute_value("src"))
				w = img.attribute_value("width").to_i
				h = img.attribute_value("height").to_i
				alt = img.attribute_value("alt")
				if (ext == img_type && w == width && h == height && alt == alt_text)
					exists = true
					loaded = img.loaded?
				end
			}
			exists
		}
		assert_score("Imagine a fost incarcata corect", "OK", "Not OK") { loaded == true }
	end

	def image_type
		$type = $prng.rand(1..3)
		case $type
		when 1
			"GIF"
		when 2
			"JPEG"
		when 3
			"PNG"
		end	
	end
	def generate
		[
			"Tipul imaginii: #{img_type}",
			"Dimensiuni imagine : #{width}x#{height}",
			"Text alternativ: #{alt_text}"
		]
	end
	def properties
		{
			:name => "Imagine (img)",
			:img_type => image_type,
			:width => $prng.rand(100..512),
			:height => $prng.rand(100..512),
			:alt_text => random_str(15)
		}
	end
end

class Categorie < Div
	def pick_category
		cat = $prng.rand(0..4)
		cats = ["Sports", "Random", "Functional Programming", "Web Development", "Cars"]
		cats[cat]
	end

	def verify(b)
		super(b)
		cat = b.div(:id => id).text
		assert_score("Verificare Categorie", "OK", "Categorie incorecta #{cat}, ar fi trebuit #{category}") { cat.include?(category) }
	end

	def generate
		[
			"ID : #{id}",
			"Categorie: #{category}"
		]
	end
	def properties
		{
			:name => "Categorie (div)",
			:id => random_str(10),
			:category => pick_category
		}
	end
end

class User < Div
	def verify(b)
		super(b)
		user = b.div(:id => id).text
		assert_score("Verificare User", "OK", "User-ul #{user} este incorect, se astepta #{username}") { user.include?(username) }
	end

	def generate
		[
			"ID: #{id}",
			"Username: #{username}"
		]
	end
	def properties
		{
			:name => "User (div)",
			:id => random_str(10),
			:username=> random_str(5).downcase + "@" + random_str(5).downcase + ".ro"
		}
	end
end

class Title < Div
	def verify(b)
		super(b)
		titlu = b.div(:id=>id).text
		assert_score("Verificare Titlu", "OK", "Se astepta #{title}") {title.include?(titlu)}
	end

	def generate
		[
			"ID: #{id}",
			"Titlu: #{title}"
		]
	end
	def properties
		{
			:name => "Titlu Articol (div)",
			:id => random_str(10),
			:title => random_str(20).upcase
		}
	end
end

class Video < HWElement
	def vid_ext(src)
		s = src.split(".")
		s[s.size-1].upcase
	end

	def verify(b)
		el = b.video
		assert_score("Verificare existenta Video", "OK", "Not OK") {
			el.exists?
		}
		assert_score("Verificare tip video", "OK", "Not OK"){
			(vid_ext(el.source.attribute_value("src")) == sources[:format_video]) && 
			(el.source.attribute_value("type") == "video/#{sources[:format_video].downcase}")
		}
		assert_score("Verificare dimensiuni video", "OK", "Not OK") {
			w = el.attribute_value("width")
			h = el.attribute_value("height")
			wh = "#{w}x#{h}"
			wh == sources[:dimensiuni]
		}
	end

	def generate_sources
		$tip = $prng.rand(1..2)
		case $tip
		when 1
			{ :format_video => "MP4", :dimensiuni => "640x480"}
		when 2
			{ :format_video => "OGG", :dimensiuni => "320x240"}
		end
	end

	def generate
		[
			"Surse video: #{sources}"
		]
	end

	def properties
		{
			:name => "Video (video tag)",
			:sources => generate_sources
		}
	end
end

class ArticleTable < HWElement
	def verify(b)
		el = b.table
		assert_score("Verificare existenta tabel", "OK", "Not OK") {
			el.exists?
		}
		assert_score("Verificare numar de randuri", "OK", "Not OK #{el.rows.size} != #{numar_randuri}"){
			el.rows.size == numar_randuri
		}
		assert_score("Verificare numar de coloane", "OK", "Not OK #{el.row.cells.size} != #{numar_coloane}"){
			el.row.cells.size == numar_coloane
		}
		el[rand_text - 1].elements[coloana_text - 1]
	end
	def subelements
		[
			Text.new
		]
	end
	def generate
		[
			"Numar de randuri: #{numar_randuri}",
			"Numar de coloane: #{numar_coloane}",
			"Randul in care se afla elementul text: #{rand_text}",
			"Coloana in care se afla elementul text: #{coloana_text}"
		]
	end
	def properties
		{
			:name => "Tabel (table)",
			:numar_randuri => $prng.rand(3..5),
			:numar_coloane => $prng.rand(3..4),
			:rand_text => $prng.rand(1..2),
			:coloana_text => $prng.rand(1..2)
		}
	end
end

class TextArticle < Div
	def subelements
		els = []
		els << Title.new
		els << Text.new
		nimg = $prng.rand(1..3)
		nimg.times{
			els << Image.new
		}
		els << ArticleTable.new if $prng.rand(1000)%2 == 0
		els << Video.new if $prng.rand(1000)%2 == 0
		els << Categorie.new
		els << User.new
		els << ArticleDate.new
		els		
	end
end

class Link < HWElement
	def verify(b)
		link = b.a(:href=>destination)
		assert_score("Existenta link catre #{destination}", "OK", "Nu exista un link catre #{destination}") { link.exists? }
		assert_score("Verificare Text Link", "OK", "Text link incorect, se astepta #{text_link}") { link.text.include?(text_link) }
	end

	def initialize(dest)
		super(properties.merge({:destination => dest} ))
	end
	
	def generate
		[
			"Pagina catre care pointeaza link-ul : #{destination}",
			"Text link : #{text_link}"
		]
	end
	
	def properties
		{
			:name => "Link (a)",
			:text_link => random_str(20).downcase
		}
	end
end

class NavigationPane < HWElement
	def verify(b)
		nav = b.nav(:id => id)
		assert_score("Existenta nav", "OK", "Tag-ul nav cu id #{id} nu este prezent") { nav.exists? }
		nav #only search the nav element for the links
	end	

	def subelements
		[
			Link.new("index.html"),
			Link.new("login.html"),
			Link.new("register.html"),
			Link.new("edit_article.html"),
			Link.new("search.html")
		]
	end

	def generate
		[
			"ID : #{id}"
		]
	end	

	def properties
		{
			:name => "Meniu de navigare (nav)",
			:id => random_str(10)
		}
	end
end


class MainPage < HTMLPage
	def subelements
		#if defined?(@els)
		#	@els
		#else
		@els = []
		@els << NavigationPane.new
		num_articles = $prng.rand(2..4)
		num_articles.times{
			@els << TextArticle.new
		}
		@els
		#end
	end

	def properties
		{
			:mandatory => true,
			:filename => "index.html",
			:name => "Pagina Principala",
			:title => random_str(25),
			:meta_keywords => "#{random_str(20)}, #{random_str(10)}"
		}
	end
end

class UserInput < HWElement
	def verify(b)
		el = b.input(:type => "text")
		assert_score("Existenta caseta de input text", "OK", "Nu exista nici un astfel de element") {
			el.exists?
		}
		assert_score("Verificare nume camp text", "OK", "Nume incorect #{el.attribute_value("name")}, se astepta #{field_name}"){
			el.attribute_value("name") == field_name
		}
		assert_score("Verificare lungime maxima camp text", "OK", "Lungime incorecta #{el.attribute_value("maxlength")}, se astepta #{maxlength}"){
			el.attribute_value("maxlength").to_i == maxlength
		}
		assert_score("Verificare text initial pentru camp", "OK", "Text initial incorect #{el.attribute_value("value")}, se astepta #{initial_text}"){
			el.attribute_value("value") == initial_text
		}

	end

	def generate
		[
			"Nume camp: #{field_name}",
			"Lungime maxima : #{maxlength}",
			"Text initial: #{initial_text}"
		]
	end
	def properties
		{
			:name => "Username (text input)",
			:field_name => random_str(10),
			:initial_text => random_str(20),
			:maxlength => $prng.rand(20..40)
		}
	end
end

class PasswordInput < HWElement
	def verify(b)
		el = b.input(:type => "password")
		assert_score("Existenta caseta de password", "OK", "Nu exista nici un astfel de element") {
			el.exists?
		}
		assert_score("Verificare nume camp password", "OK", "Nume incorect #{el.attribute_value("name")}, se astepta #{field_name}"){
			el.attribute_value("name") == field_name
		}
		assert_score("Verificare lungime maxima camp text", "OK", "Lungime incorecta #{el.attribute_value("maxlength")}, se astepta #{maxlength}"){
			el.attribute_value("maxlength").to_i == maxlength
		}

	end
	def generate
		[
			"Nume camp: #{field_name}",
			"Lungime maxima : #{maxlength}"
		]
	end
	def properties
		{
			:name => "Parola (password input)",
			:field_name => random_str(10),
			:maxlength => $prng.rand(20..40)
		}
	end
end

class SubmitButton < HWElement
	def verify(b)
		sb = b.input(:type => "submit")
		assert_score("Verificare Prezenta Submit", "OK", "Nu a fost gasit nici un buton de submit") { sb.exists? }
		assert_score("Verificare Text Submit", "OK", "Se astepta ca butonul de submit sa aiba textul #{button_text}") { sb.value.include?(button_text) }
	end
	def generate
		[
			"Text button login: #{button_text}"
		]
	end
	def properties
		{
			:name => "Buton Login (submit input)",
			:button_text => "Login to " + random_str(10)
		}
	end
end

class LoginForm < HWElement
	def verify(b)
		form = b.form(:action => pagina_destinatie)
		assert_score("Verificare existenta formular", "OK", "Nu exista nici un element form care sa se submita catre #{pagina_destinatie}") { form.exists? }
		assert_score("Verificare metoda de submit formular", "OK", "Metoda incorecta, se astepta #{form_method}") { form.attribute_value("method").upcase == form_method }
		form
	end
	def subelements
		[
			UserInput.new,
			PasswordInput.new,
			SubmitButton.new
		]
	end
	
	def gen_method
		m = $prng.rand(1..2)
		case m
		when 1
			"POST"
		when 2
			"GET"
		end
	end
	
	def generate
		[
			"Pagina Destinatie : #{pagina_destinatie}",
			"Metoda formular : #{form_method}"
		]
	end	

	def properties
		{
			:name => "Formular (form)",
			:pagina_destinatie => "index.html",
			:form_method => gen_method
		}
	end
end

class LoginPage < HTMLPage
	def subelements
		[
			LoginForm.new
		]
	end

	def properties
		{
			:mandatory => false,
			:filename => "login.html",
			:name => "Pagina Login",
			:title => random_str(25),
			:meta_keywords => "login, #{random_str(20)}"
		}
	end
end

class SearchField < HWElement	
	def verify(b)
		el = b.input(:type => "text")
		assert_score("Existenta caseta de input text", "OK", "Nu exista nici un astfel de element") {
			el.exists?
		}
		assert_score("Verificare nume camp text", "OK", "Nume incorect #{el.attribute_value("name")}, se astepta #{field_name}"){
			el.attribute_value("name") == field_name
		}
		assert_score("Verificare lungime maxima camp text", "OK", "Lungime incorecta #{el.attribute_value("maxlength")}, se astepta #{maxlength}"){
			el.attribute_value("maxlength").to_i == maxlength
		}
		assert_score("Verificare text initial pentru camp", "OK", "Text initial incorect #{el.attribute_value("value")}, se astepta #{initial_text}"){
			el.attribute_value("value") == initial_text
		}

	end

	def generate
		[
			"Nume camp: #{field_name}",
			"Lungime maxima : #{maxlength}",
			"Text initial: #{initial_text}"
		]
	end

	def properties
		{
			:name => "Caseta cautare (text input)",
			:field_name => random_str(10),
			:initial_text => random_str(20),
			:maxlength => $prng.rand(20..40)
		}
	end
end

class SearchSubmit < HWElement
	def verify(b)
		sb = b.input(:type => "submit")
		assert_score("Verificare Prezenta Submit", "OK", "Nu a fost gasit nici un buton de submit") { sb.exists? }
		assert_score("Verificare Text Submit", "OK", "Se astepta ca butonul de submit sa aiba textul #{button_text}") { sb.value.include?(button_text) }
	end

	def generate
		[
			"Text buton: #{button_text}"
		]
	end

	def properties
		{
			:name => "Cautare (submit input)",
			:button_text => random_str(10)
		}
	end
end

class SearchForm < HWElement
	
	def verify(b)
		form = b.form(:action => pagina_destinatie)
		assert_score("Verificare existenta formular", "OK", "Nu exista nici un element form care sa se submita catre #{pagina_destinatie}") { form.exists? }
		assert_score("Verificare metoda de submit formular", "OK", "Metoda incorecta, se astepta #{form_method}") { form.attribute_value("method").upcase == form_method }
		form
	end

	def subelements
		[
			SearchField.new,
			SearchSubmit.new
		]
	end

	def gen_method
		m = $prng.rand(1..2)
		case m
		when 1
			"POST"
		when 2
			"GET"
		end
	end
	
	def generate
		[
			"Pagina Destinatie : #{pagina_destinatie}",
			"Metoda formular : #{form_method}"
		]
	end	

	def properties
		{
			:name => "Formular Cautare (form)",
			:pagina_destinatie => "index.html",
			:form_method => gen_method
		}
	end
end

class SearchPage < HTMLPage
	def subelements
		[
			SearchForm.new
		]
	end
	def properties
		{
			:mandatory => false,
			:filename => "search.html",
			:name => "Pagina Cautare",
			:title => "Cautare " + random_str(10),
			:meta_keywords => "cautare, #{random_str(20)}"
		}
	end
end

$pwelements = [ MainPage, LoginPage, SearchPage ]
