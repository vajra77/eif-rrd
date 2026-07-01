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

	rrd_update_c (a_argc: INTEGER; a_argv: POINTER): INTEGER
    			-- Invocazione diretta di int rrd_update(int argc, char **argv)
    		external
    			"C inline use <rrd.h>"
    		alias
    			"return rrd_update((int)$a_argc, (char **)$a_argv);"
    		end

    rrd_get_error_c: POINTER
    			-- Restituisce il puntatore char* all'ultimo errore
    		external "C inline use <rrd.h>"
    		alias "return rrd_get_error();"
    		end

    rrd_clear_error_c
    		-- Resetta lo stato dell'errore nativo
    		external "C inline use <rrd.h>"
    		alias "rrd_clear_error();"
    		end

    rrd_fetch_c (
    		a_argc: INTEGER;
    		a_argv: POINTER;
    		a_start: POINTER;
    		a_end: POINTER;
    		a_step: POINTER;
    		a_ds_cnt: POINTER;
    		a_ds_namv: POINTER;
    		a_data: POINTER
    	): INTEGER
    		external
    			"C inline use <rrd.h>"
    		alias
    			"return rrd_fetch((int)$a_argc, (char **)$a_argv, (time_t *)$a_start, (time_t *)$a_end, (unsigned long *)$a_step, (unsigned long *)$a_ds_cnt, (char ***)$a_ds_namv, (rrd_value_t **)$a_data);"
    		end

end