# Making some assumptions: dumb file name parsing, and that files will follow
# Nand2Tetris syntactic conventions (variables = lowercase, loops = uppercase).
# Assembler is also very brittle.

class Parser

	def initialize(filename)
		@simplified_filename = filename.split('.').first
		@file_contents = File.open(filename).read
		@lines_of_assembly = self.clean_lines
		@lines_of_binary = []
		@symbol_table = SymbolTable.new()
	end

	def clean_lines
		lines_of_code = @file_contents.split(/\r?\n/).map do |line|
			if line.include?('//')
				parts_of_line = line.split('//')
				uncommented_code = parts_of_line.first
				line = uncommented_code
			end
			line.strip
		end
		lines_of_code.reject! { |line| line.empty? }
		return lines_of_code
	end

	def parse
		@lines_of_binary = @lines_of_assembly.each_with_index.map do |line, index|
			if line.start_with?('@')
				ACommand.new(@symbol_table, line).parse
			elsif line.start_with?('(')
				LCommand.new(@symbol_table, line).parse(index)
			else
				CCommand.new(@symbol_table, line).parse
			end
		end

		# So I can return '' from an LCommand, which just adds a symbol to the
		# symbol table. Also go through and check for any lines that are
		# strings of letters, which means it's an A command placeholder.
		@lines_of_binary = @lines_of_binary.reject { |line| line.empty? }.map do |line|
			line.scan(/\D+/).empty? ? line : ACommand.new(@symbol_table, line).parse
		end
	end

	def save
		binary_file_name = @simplified_filename + '.hack'
		save_file = File.open(binary_file_name, mode = 'w')
		for line in @lines_of_binary
			save_file.write("#{line}\n")
		end
		return binary_file_name
	end

end

class LineOfCode

	def initialize(symbol_table, line)
		@symbol_table = symbol_table
		@line = line
	end

	def parse
		return @line
	end

end

class ACommand < LineOfCode
	
	def parse
		value = @line.sub('@', '')
		value.scan(/\D+/).empty? ? self.parse_integer(value) : self.parse_symbol(value)
	end

	def parse_integer(number)
		number_in_binary = "%b" % number
		return '0' * (16 - number_in_binary.length) + number_in_binary
	end

	def parse_symbol(symbol)
		if symbol.downcase == symbol
			# is a variable
			return self.parse_integer(@symbol_table.fetch_or_insert_symbol(symbol))
		else
			# is a loop
			location = @symbol_table.fetch_symbol(symbol)
			location.is_a?(Integer) ? self.parse_integer(location) : symbol
		end
	end

end

class LCommand < LineOfCode

	def parse(index)
		symbol = @line[1...-1]
		@symbol_table.insert_symbol(symbol, index)
		return ''
	end

end

class CCommand < LineOfCode

	def parse
		match_data = @line.match(/(?<destination>\w*)=*(?<computation>[\w\+]*);*(?<jump>\w*)/)
		destination = self.calculate_destination(match_data[:destination])
		computation = self.calculate_computation(match_data[:computation])
		jump = self.calculate_jump(match_data[:jump])

		if match_data[:computation].include?('M')
			a_or_m = '1'
		else
			a_or_m = '0'
		end

		command_in_binary = '111' + a_or_m + computation + destination + jump
	end

	def calculate_destination(assembly_string)
		if assembly_string.include?('A')
			a_bit = '1'
		else
			a_bit = '0'
		end

		if assembly_string.include?('D')
			d_bit = '1'
		else
			d_bit = '0'
		end

		if assembly_string.include?('M')
			m_bit = '1'
		else
			m_bit = '0'
		end

		return a_bit + d_bit + m_bit
	end

	def calculate_computation(assembly_string)
		# Some tidying up so I have to test for fewer cases.
		assembly_string.gsub!('M', 'A')

		# Short-circuit for constants.
		return '101010' if assembly_string == '0' or assembly_string == ''
		return '111111' if assembly_string == '1'
		return '111010' if assembly_string == '-1'

		c2_1_bit_computations = ['D+1', 'D-A', 'D|A']
		if assembly_string.include?('D')
			c1_bit = '0'

			c2_1_bit_computations.include?(assembly_string) ? c2_bit = '1' : c2_bit = '0'
		else
			c1_bit = '1'
			c2_bit = '1'
		end

		c4_1_bit_computations = ['A+1', 'A-D', 'D|A']
		if assembly_string.include?('A')
			c3_bit = '0'

			c4_1_bit_computations.include?(assembly_string) ? c4_bit = '1' : c4_bit = '0'
		else
			c3_bit = '1'
			c4_bit = '1'
		end

		c5_0_bit_characters = ['!', '&', '|']
		if assembly_string.length == 1 or c5_0_bit_characters.any? { |char| assembly_string.include?(char) }
			c5_bit = '0'
		else
			c5_bit = '1'
		end

		c6_0_bit_characters = ['-1', '&', '+A']
		if assembly_string.length == 1 or c6_0_bit_characters.any? { |char| assembly_string.include?(char) }
			c6_bit = '0'
		else
			c6_bit = '1'
		end

		return c1_bit + c2_bit + c3_bit + c4_bit + c5_bit + c6_bit
	end

	def calculate_jump(assembly_string)
		case assembly_string
		when ''
			return '000'
		when 'JMP'
			return '111'
		when 'JEQ'
			return '010'
		when 'JNE'
			return '101'
		when 'JGT'
			return '001'
		when 'JGE'
			return '011'
		when 'JLT'
			return '100'
		when 'JLE'
			return '110'
		end
	end

end

class SymbolTable

	PREDEFINED_SYMBOLS = {
		'SP' => 0,
		'LCL' => 1,
		'ARG' => 2,
		'THIS' => 3,
		'THAT' => 4,
		'R0' => 0,
		'R1' => 1,
		'R2' => 2,
		'R3' => 3,
		'R4' => 4,
		'R5' => 5,
		'R6' => 6,
		'R7' => 7,
		'R8' => 8,
		'R9' => 9,
		'R10' => 10,
		'R11' => 11,
		'R12' => 12,
		'R13' => 13,
		'R14' => 14,
		'R15' => 15,
		'SCREEN' => 16384,
		'KBD' => 24576
	}

	def initialize
		@variable_counter = 16
		@symbol_table = PREDEFINED_SYMBOLS.dup
	end

	def fetch_or_insert_symbol(symbol)
		return self.fetch_symbol(symbol) || self.insert_symbol(symbol)
	end

	def fetch_symbol(symbol)
		return @symbol_table[symbol]
	end

	def insert_symbol(symbol, location=nil)
		@symbol_table[symbol] = location || self.calculate_next_slot
	end

	def calculate_next_slot
		next_slot = @variable_counter
		@variable_counter += 1
		return next_slot
	end

end

if ARGV[0]
	parser = Parser.new(ARGV[0])
	parser.parse
	filename = parser.save
	puts "Saved new binary file #{filename}."
else
	puts "I need a .asm file as an argument!"
end
