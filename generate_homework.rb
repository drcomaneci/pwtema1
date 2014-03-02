require 'pwelements'

def generate_hw(student_name)
	seed = student_name.to_i(36)
	$prng = Random.new(seed)
	desc = $pwelements.map{ |element|
		elemobj = element.new
		if (elemobj.mandatory || $prng.rand(1..10000)%2 == 0)
			elemobj.generate_description
		else
			""
		end
	}.join("\n")
	puts desc
end

if ARGV.size != 1
	puts "Generatorul de tema primeste numele vostru ca input. Eg. ruby -I . generate_homework.rb \"Dragos Comaneci\""
end

generate_hw(ARGV[0])
