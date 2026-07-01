note
	description: "Interfaccia di basso livello verso librrd.dylib"

class
	RRD_NATIVE_API

feature -- Funzioni Esterne C

	rrd_create_c (a_argc: INTEGER; a_argv: POINTER): INTEGER
			-- Invocazione diretta di int rrd_create(int argc, char **argv)
		external
			"C inline use <rrd.h>"
		alias
			"return rrd_create((int)$a_argc, (char **)$a_argv);"
		end

end