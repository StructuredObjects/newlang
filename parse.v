import os

fn main() {
	mut new_c_gen := ""
	content := os.read_file("example.new") or {
		print("[!] Error, Unable to read file")
		exit(0)
	}

	pwd := (os.execute("pwd").output).replace("\r", "").replace("\n", "")
	lines := content.split("\n")

	mut file_line := 0
	for line in lines
	{
		file_line++
		if line.len == 0 || lines.len < 2 { continue }

		if line.starts_with("C_BLOCK{") {
			for cblock in file_line..lines.len {
				if lines[cblock] == "}" { break }
				new_c_gen += "${lines[cblock]}\n"
			}
		}

		/* Function Parser */
		if line.starts_with("fnc") {
			fnc_line := line.trim_space().split(" ")

			if fnc_line.len < 2 {
				print("${pwd}/example.new:${file_line} [!] Error, Invalid function syntax...")
				exit(0)
			}

			if line.trim_space().ends_with("{") == false && lines[file_line].trim_space().contains("{") == false {
				print("${pwd}/example.new:${file_line} [!] Missing opening bracket for function.....")
				exit(0)
			}

			mut fnc_code := ""
			mut last_line := ""
			for o in file_line..lines.len
			{
				if lines[o].trim_space() == "" { continue }
				if lines[o].starts_with("{") != true || lines[o].starts_with("}") != true {
					if lines[o].ends_with(";") != true { 
						print(lines[o])
						print("${pwd}/example.new:${file_line} [!] Missing semi-colon at the end of line...")
						print(lines[o] + "\n")
						exit(0)
					}
				}
				if lines[o].trim_space().starts_with("}") && lines[o].trim_space().ends_with(";") {
					if lines[o] == "};" {
						print("${pwd}/example.new:${file_line} [!] Invalid function end syntax")
						exit(0)
					}
					last_line = lines[o]
					break
				}
				if lines[o].trim_space().starts_with("C.") {
					fnc_code += lines[o].replace("C.", "") + "\n"
				} else { fnc_code += "${lines[o]}\n" }
			}
			last_line_info := last_line.split(" ")

			/* FUNCTION INFO */
			fnc_type := last_line.replace("}", "").replace(";", "").trim_space() // TYPE CHECKING HERE
			fnc_name := remove_after(fnc_line[1], "(") // FUNCTION NAME CHECKING HERE
			fnc_arg := get_str_between(line, "(", ")") // TYPE CHECKING ARGS & SPECIAL ARG SYNTAX
			cgen_args := fnc_arg_cgen(parse_args(fnc_arg.replace("(", "").replace(")", "")))
			new_c_gen += "${fnc_type} ${fnc_name}(${cgen_args})\n{\n${fnc_code}\n}\n"
		}
	}
	print(new_c_gen)

	os.write_file("example.c", new_c_gen) or { return }
	os.execute("gcc example.c -o example").output
}

pub fn parse_args(args string) map[string]string
{
	arguments := args.split(",")
	// new syntax ['argc: int', 'argv: array']
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
			new += cgen_newtypes(v.trim_space()) + " ${k.trim_space()}"
		} else { new += cgen_newtypes(v.trim_space()) + " ${k.trim_space()}, " }
		c++
	}
	return new
}

pub fn cgen_newtypes(typ []string) string
{
	match typ[0] {
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