require 'ostruct'
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
		subelem_gen = subelements.map{|elem| elem.generate_description(level+1)}.join("\n")
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
	def generate
		[
			"Numele fisierului HTML: #{filename}",
			"Titlul paginii : #{title}",
			"Meta Keywords : #{meta_keywords}"
		]	
	end
end

class Div < HWElement
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
		els = []
		els << NavigationPane.new
		num_articles = $prng.rand(2..4)
		num_articles.times{
			els << TextArticle.new
		}
		els
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
