import os

pub struct NEWLANG 
{
	pub mut:
		current_pwd		string
		filepath		string
		on_line			string

		/* In Code Line Settings */
		in_var			bool
		in_fnc			bool

		in_if			bool
		in_cblk			bool
}

const (
	datatypes = ["string", "array", "bool"]
)

fn main() {
	mut new_c_gen := ""
	mut in_fnc := false
	mut in_var := false
	
	args := os.args.clone() 
	args_len := args.len

	if args_len < 2 {
		print("[!] Error, No '.new' file provided...!\n")
		exit(0)
	}

	file := args[1] 

	if file.ends_with(".new") != true && os.exists(file) != true {
		print("[!] Error, Invalid file provided...!\n")
		exit(0)
	}
	
	content := os.read_file("example.new") or {
		print("[!] Error, Unable to read file...!\n")
		exit(0)
	}

	lines := content.split("\n")

	for file_line in 0..lines.len
	{
		line := lines[file_line]

		/* Making sure we got code in line or skip */
		if line.len == 0 || lines.len < 2 { 
			new_c_gen += "\n"
			continue 
		}

		
		/* Catching C_BLOCK{}s */
		if line.starts_with("C_BLOCK{") && in_fnc == false {

			for cblock in file_line+1..lines.len {
				if lines[cblock] == "}" { break }
				new_c_gen += "${lines[cblock]}\n"
			}
		}

		/* Function Parser */
		if line.starts_with("fnc") {
			new_c_gen += parse_fnc(content, file_line, content.split("\n").len)
		}
	}

	os.write_file("example.c", new_c_gen) or { return }
	output := os.execute("gcc example.c -o example").output

	if output.trim_space().contains("error") { 
		print("[!] C Error compiling....\n")
		for line in output.split("\n")
		{
			if line.contains("error") {
				err := line.replace("error", "\x1b[31merror\x1b[0m")
				print("${err}\n")
			}
		}
	} else {
		print("[+] Successfully compiled....\n")
	}
}

pub fn parse_var(var_line string) string {
	// int t = 0;
	// string t = "";
	// string t;
	var_info := var_line.trim_space().split(" ")

	if var_info.len == 2 {
		return var_line.replace(var_info[0], cgen_newtypes(var_info[0]))
	} else if var_info.len == 4 {
		return var_line.replace(var_info[0], cgen_newtypes(var_info[0]))
	}
	return ""
}

pub fn parse_fnc(file_content string, line_num int, end int) string {
	mut fnc_code := ""
	mut last_line := ""
	mut cgen_args := ""
	mut in_clk := false
	mut in_if := false
	mut in_var := false
	
	lines := file_content.split("\n")
	first_line := lines[line_num]
	fnc_line := lines[line_num].trim_space().split(" ")

	/* Verifying opening function bracket */
	if lines[line_num].contains("{") != true || lines[line_num].contains("{") != true {
		print("[!] Missing opening function bracket")
		exit(0)
	}

	mut file_line := line_num

	for _ in line_num+1..end+1
	{
		line := lines[file_line]

		/* Catching end of function */
		if line.starts_with("}") && line.ends_with(";") {
			last_line = line
			break
		}

		/* Catching variables */
		for var in datatypes
		{
			if line.trim_space().starts_with(var) {
				fnc_code += "${parse_var(line)}\n"
				break
			}
		}

		/* Catching C_BLOCK{}s within functions */
		if line.trim_space().starts_with("C_BLOCK{") {
			in_clk = true
			mut cblock := file_line
			for {
				c_line := lines[cblock]
				if c_line.trim_space() == "};" && in_if == false {
					in_clk = false
					file_line = cblock
					break }
				if c_line.trim_space().starts_with("};") == false || line.trim_space() != "C_BLOCK{" { fnc_code += "${lines[cblock]}\n" }
				cblock++
			}
		}
		
		/* Append code if not in C_Block{} */
		if line.starts_with("fnc") != true && line.trim_space() != "};" && line.trim_space().starts_with("C_BLOCK{") != true && in_clk == false { // Ignoring C_BLOCK{}s
			if line.trim_space().split(" ").len > 1 && in_array(datatypes, line.trim_space().split(" ")[0]) {} else { // Ignoring variables
				fnc_code += "${line}\n".replace("C.", "") 
			}
		}
		file_line++
	}

	/* FUNCTION INFO */
	fnc_type := last_line.replace("}", "").replace(";", "").trim_space() // TYPE CHECKING HERE
	fnc_name := remove_after(fnc_line[1], "(") // FUNCTION NAME CHECKING HERE
	if first_line.contains("()") != true {
		fnc_arg := get_str_between(first_line, "(", ")") // TYPE CHECKING ARGS & SPECIAL ARG SYNTAX
		cgen_args = fnc_arg_cgen(parse_args(fnc_arg.replace("(", "").replace(")", "")))
	}
	return "${fnc_type} ${fnc_name}(${cgen_args})\n{\n${fnc_code.replace("C_BLOCK{", "")}\n}"
}

pub fn parse_args(args string) map[string]string
{
	arguments := args.split(",")
	mut sorted := map[string]string{}
	for arg in arguments
	{
		info := arg.split(": ")
		sorted[info[0]] = info[1]
	}
	return sorted
}

pub fn fnc_arg_cgen(args map[string]string) string 
{
	mut new := ""
	mut c := 0
	for k, v in args
	{
		if c == args.len-1 {
			new += cgen_newtypes("${v}".trim_space()) + " ${k.trim_space()}"
		} else { new += cgen_newtypes("${v}".trim_space()) + " ${k.trim_space()}, " }
		c++
	}
	return new
}

pub fn cgen_newtypes(typ string) string
{
	match typ {
		"array" {
			return "char **"
		}
		"string" {
			return "char *"
		} else { return typ }
	}
	return typ
}

pub fn get_str_between(str string, start string, end string) string
{
	mut new := ""
	mut capture := false
	for i in str
	{
		if capture { new += i.ascii_str() }
		if i.ascii_str() == start && new == "" { capture = true }
		if i.ascii_str() == end && new != "" { return new }
	}
	return ""
}

pub fn remove_after(str string, eol string) string
{
	mut new := ""
	for i in str
	{
		if i.ascii_str() == eol { return new }
		new += i.ascii_str()
	}
	return ""
}

pub fn in_array(arr []string, key string) bool {
	if key in arr { return true }
	return false
}