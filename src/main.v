import os

fn main()
{
	args := os.args.clone()

	if args.len < 2 {
		print("[!] Error, No '.new' file provided\n")
		exit(0)
	}

	main_file := args[1]

	if args[1] != ".new" && os.exists(main_file) != true {
		print("[!] Error, Invalid '.new' file provided")
		exit(0)
	}

	for arg in args 
	{
		if arg == "-run" {

		}
	}

	
}