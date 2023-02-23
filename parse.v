import os

fn main() {
	mut new_c_gen := ""
	mut in_fnc := false
	
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
		if line.len == 0 || lines.len < 2 { 
			new_c_gen += "\n"
			continue 
		}

		if line.starts_with("C_BLOCK{") && in_fnc == false{
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
	} else {
		print("[+] Successfully compiled....\n")
	}
}

pub fn parse_fnc(file_content string, line_num int, end int) string {
	mut fnc_code := ""
	mut last_line := ""
	mut cgen_args := ""
	
	lines := file_content.split("\n")
	first_line := lines[line_num]
	fnc_line := lines[line_num].trim_space().split(" ")

	/* Verifying opening function bracket*/
	if lines[line_num].contains("{") != true || lines[line_num].contains("{") != true {
		print("[!] Missing opening function bracket")
		exit(0)
	}

	mut file_line := line_num
	for _ in line_num+1..end+1
	{
		line := lines[file_line]

		if line.starts_with("}") && line.ends_with(";") {
			last_line = line
			break
		}
		
		/* Append code if not in C_Block{} */
		if line.starts_with("fnc") != true { fnc_code += "${line}\n".replace("C.", "") }
		file_line++
	}

	/* FUNCTION INFO */
	fnc_type := last_line.replace("}", "").replace(";", "").trim_space() // TYPE CHECKING HERE
	fnc_name := remove_after(fnc_line[1], "(") // FUNCTION NAME CHECKING HERE
	if first_line.contains("()") != true {
		fnc_arg := get_str_between(first_line, "(", ")") // TYPE CHECKING ARGS & SPECIAL ARG SYNTAX
		cgen_args = fnc_arg_cgen(parse_args(fnc_arg.replace("(", "").replace(")", "")))
	}
	return "${fnc_type} ${fnc_name}(${cgen_args})\n{\n${fnc_code}\n}"
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