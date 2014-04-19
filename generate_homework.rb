require 'pwelements'

def generate_hw(student_name)
	seed = student_name.to_i(36)
	$prng = Random.new(seed)
	$elemobjs = []
	desc = $pwelements.map{ |element|
		elemobj = element.new
		if (elemobj.mandatory || $prng.rand(1..10000)%2 == 0)	
			$elemobjs << elemobj
			elemobj.generate_description
		else
			""
		end
	}.join("\n")
end

if ARGV.size < 1
	puts "Generatorul de tema primeste numele vostru ca input. Eg. ruby -I . generate_homework.rb \"Dragos Comaneci\""
	puts "Pentru a valida tema, puteti adauga parametru -t imediat dupa numele vostru. Fisierele HTML trebuie sa se afle in folderul curent de unde este apelat scriptul. Eg. ruby -I . generate_homework.rb \"Dragos Comaneci\" -t"
end

desc = generate_hw(ARGV[0])
if (ARGV.size == 2 && ARGV[1]=="-t")
	puts "Validating homework"
	require 'watir-webdriver'
	b = Watir::Browser.new :chrome
	$elemobjs.each{ |el|
		begin
			el.verifyr(b)
		rescue Exception => e
			puts e.message
			puts e.backtrace.inspect
			b.close()
		end
	}
	b.close
	score = $passed.to_f/$attempt.to_f
	puts "Scor final #{$passed} / #{$attempt} = #{score} * 0.8 = #{score * 0.8}"
else
	puts desc
end
