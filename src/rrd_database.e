note
	description: "Rappresentazione logica di un file RRD e delle operazioni su di esso"

class
	RRD_DATABASE

create
	make

feature {NONE} -- Inizializzazione

	make (a_filename: STRING; a_step: INTEGER)
		require
			filename_valido: a_filename /= Void and then not a_filename.is_empty
			step_positivo: a_step > 0
		do
			filename := a_filename
			step := a_step
			create {ARRAYED_LIST [RRD_DATA_SOURCE]} data_sources.make (0)
			create {ARRAYED_LIST [RRD_ARCHIVE]} archives.make (0)
		ensure
			filename_impostato: filename = a_filename
			step_impostato: step = a_step
		end

feature -- Elementi costruttivi

	filename: STRING
	step: INTEGER
	data_sources: LIST [RRD_DATA_SOURCE]
	archives: LIST [RRD_ARCHIVE]

feature -- Operazioni di configurazione

	add_data_source (a_ds: RRD_DATA_SOURCE)
		require
			ds_presente: a_ds /= Void
		do
			data_sources.extend (a_ds)
		ensure
			aggiunto: data_sources.count = old data_sources.count + 1
		end

	add_archive (a_rra: RRD_ARCHIVE)
		require
			rra_presente: a_rra /= Void
		do
			archives.extend (a_rra)
		ensure
			aggiunto: archives.count = old archives.count + 1
		end

feature -- Interfaccia dei comandi (Chiamate C esterne)

    create_on_disk
			-- Crea fisicamente il file RRD sul disco tramite la libreria C.
		require
			ha_ds: not data_sources.is_empty
			ha_rra: not archives.is_empty
		local
			args: ARRAYED_LIST [STRING]
			native_api: RRD_NATIVE_API
			c_strings: ARRAYED_LIST [ANY]
			argv: MANAGED_POINTER
			i, rc: INTEGER
			pos: INTEGER
			c_string_tool: C_STRING
		do
			create args.make (0)
			create c_strings.make (0)
			create native_api

			-- 1. Costruiamo la lista degli argomenti
			args.extend ("create")
			args.extend (filename)
			args.extend ("--step")
			args.extend (step.out)

			across data_sources as ds_item loop
				args.extend (ds_item.as_argument_string)
			end

			across archives as rra_item loop
				args.extend (rra_item.as_argument_string)
			end

			-- 2. Allocazione della struttura dei puntatori C (char * argv[])
			-- MANAGED_POINTER alloca i byte necessari. Calcoliamo: numero di argomenti * dimensione del puntatore di sistema
			create argv.make (args.count * {PLATFORM}.pointer_bytes)

			-- 3. Popoliamo l'array con i puntatori alle stringhe C
			from
				i := 1
				pos := 0
			until
				i > args.count
			loop
				create c_string_tool.make (args.at (i))
				c_strings.extend (c_string_tool) -- Protegge la stringa C dal GC

				-- Scriviamo l'indirizzo della stringa C nel buffer (usa l'offset in byte)
				argv.put_pointer (c_string_tool.item, pos)

				pos := pos + {PLATFORM}.pointer_bytes
				i := i + 1
			end

			-- 4. Invocazione della libreria C nativa passando l'indirizzo base del MANAGED_POINTER
			print ("Invocazione di rrd_create tramite librrd.dylib...%N")
			rc := native_api.rrd_create_c (args.count, argv.item)
			print ("Risultato del comando rrd_create C: " + rc.out + "%N")

			-- 5. Non serve fare memory_free! MANAGED_POINTER rilascia la memoria C automaticamente.
			check successo: rc = 0 end
		end

	update (a_timestamp: STRING; a_values: LINKED_LIST [STRING])
    			-- Inserisce una nuova riga di dati nel database RRD.
    			-- `a_timestamp` può essere un timestamp Unix o "N" (Now).
    		require
    			database_configurato: not data_sources.is_empty
    			timestamp_valido: a_timestamp /= Void and then not a_timestamp.is_empty
    			valori_coerenti: a_values /= Void and then a_values.count = data_sources.count
    		local
    			args: ARRAYED_LIST [STRING]
    			native_api: RRD_NATIVE_API
    			c_strings: ARRAYED_LIST [ANY]
    			argv: MANAGED_POINTER
    			i, rc: INTEGER
    			pos: INTEGER
    			c_string_tool: C_STRING
    			update_data: STRING
    		do
    			create args.make (0)
    			create c_strings.make (0)
    			create native_api

    			-- 1. Costruiamo gli argomenti della CLI C: rrdtool update filename timestamp:val1:val2
    			args.extend ("update")
    			args.extend (filename)

    			-- Componiamo la stringa dei dati (es. "N:1024" o "1719825162:5000")
    			create update_data.make_from_string (a_timestamp)
    			across a_values as val_item loop
    				update_data.append (":" + val_item)
    			end
    			args.extend (update_data)

    			-- 2. Allocazione del vettore di puntatori C (char **argv)
    			create argv.make (args.count * {PLATFORM}.pointer_bytes)

    			-- 3. Riempimento del buffer con le stringhe C
    			from
    				i := 1
    				pos := 0
    			until
    				i > args.count
    			loop
    				create c_string_tool.make (args.at (i))
    				c_strings.extend (c_string_tool) -- Protezione dal Garbage Collector

    				argv.put_pointer (c_string_tool.item, pos)

    				pos := pos + {PLATFORM}.pointer_bytes
    				i := i + 1
    			end

                -- 4. Chiamata alla libreria C
			    rc := native_api.rrd_update_c (args.count, argv.item)

			    -- 5. Controllo dell'esito con diagnostica
			    if rc /= 0 then
				    print ("Errore durante l'update del file RRD. Codice C: " + rc.out + "%N")
				    print_error (native_api)
			    else
				    print ("Dati inseriti con successo nel database RRD!%N")
			    end
    		end

    fetch (a_cf: STRING; a_start, a_end: STRING)
    			-- Recupera i dati dal database RRD per il periodo specificato.
    		require
    			cf_presente: a_cf /= Void and not a_cf.is_empty
    			start_presente: a_start /= Void
    			end_presente: a_end /= Void
    		local
    			args: ARRAYED_LIST [STRING]
    			native_api: RRD_NATIVE_API
    			c_strings: ARRAYED_LIST [ANY]
    			argv: MANAGED_POINTER
    			i, rc: INTEGER
    			pos: INTEGER
    			c_string_tool: C_STRING

    			-- Puntatori per i parametri di output del C
    			c_start, c_end, c_step, c_ds_cnt: MANAGED_POINTER
    			c_ds_namv, c_data: MANAGED_POINTER

    			-- Variabili per scorrere i risultati restituiti
    			ds_count: INTEGER
    			row_count: INTEGER
    			r, d: INTEGER
    			ds_name_ptr: POINTER
    			valore_double: REAL_64
    		do
    			create args.make (0)
    			create c_strings.make (0)
    			create native_api

    			-- 1. Setup degli argomenti CLI-style per il fetch: rrdtool fetch filename CF [--start S] [--end E]
    			args.extend ("fetch")
    			args.extend (filename)
    			args.extend (a_cf)
    			args.extend ("--start")
    			args.extend (a_start)
    			args.extend ("--end")
    			args.extend (a_end)

    			create argv.make (args.count * {PLATFORM}.pointer_bytes)
    			from i := 1; pos := 0 until i > args.count loop
    				create c_string_tool.make (args.at (i))
    				c_strings.extend (c_string_tool)
    				argv.put_pointer (c_string_tool.item, pos)
    				pos := pos + {PLATFORM}.pointer_bytes
    				i := i + 1
    			end

    			-- 2. Allocazione delle variabili di output C (time_t e unsigned long)
    			-- Usiamo la dimensione standard dei numeri a 64-bit per macOS (8 byte)
    			create c_start.make (8)
    			create c_end.make (8)
    			create c_step.make (8)
    			create c_ds_cnt.make (8)

    			-- Allocazione dei puntatori ai vettori di ritorno (char*** e rrd_value_t**)
    			create c_ds_namv.make ({PLATFORM}.pointer_bytes)
    			create c_data.make ({PLATFORM}.pointer_bytes)

    			-- 3. Invocazione della chiamata C
    			print ("Esecuzione di rrd_fetch via C-Binding...%N")
    			rc := native_api.rrd_fetch_c (
    				args.count, argv.item,
    				c_start.item, c_end.item, c_step.item, c_ds_cnt.item,
    				c_ds_namv.item, c_data.item
    			)

    			if rc /= 0 then
    				print ("Errore durante il fetch dei dati RRD.%N")
    				-- Se hai implementato stampa_errore_nativo dall'ultimo step:
    				-- stampa_errore_nativo (native_api)
    			else
    				-- 4. Estrazione e parsing dei dati restituiti con successo dal C
    				ds_count := c_ds_cnt.read_integer_64 (0).to_integer_32
    				print ("Numero di Data Sources trovati: " + ds_count.out + "%N")

    				-- Calcoliamo quante righe temporali sono state restituite
    				-- Formula RRDtool: ((end - start) / step) + 1
    				row_count := ((c_end.read_integer_64 (0) - c_start.read_integer_64 (0)) // c_step.read_integer_64 (0)).to_integer_32 + 1
    				print ("Numero di intervalli temporali (righe): " + row_count.out + "%N")

    				-- TODO: Qui potremmo mappare i nomi dei DS leggendo da c_ds_namv.read_pointer(0)
    				-- Ma andiamo dritti al sodo estraendo i valori numerici grezzi dal vettore c_data
    				if c_data.read_pointer (0) /= Void then
    					print ("--- ESTREMO VALORI DAL BUFFER C ---%N")
    					-- Il buffer dei dati è una matrice lineare row_count * ds_count di Double (8 byte ciascuno)
    					from r := 0 until r >= row_count loop
    						print ("Riga " + (r + 1).out + ": ")
    						from d := 0 until d >= ds_count loop
    							-- Calcoliamo l'offset in byte all'interno del mega-array restituito dal C
    							pos := (r * ds_count + d) * 8

    							-- Leggiamo il Double direttamente dalla memoria dereferenziata
    							-- Nota: Usiamo una lettura C inline sicura passando il puntatore base di c_data
    							valore_double := estrai_double_da_matrice (c_data.read_pointer (0), pos)

    							print (valore_double.out + "  ")
    							d := d + 1
    						end
    						print ("%N")
    						r := r + 1
    					end

    					-- NOTA: In C puro dovresti fare il free() di *ds_namv e *data allocati da rrd_fetch.
    					-- Per questo test iniziale lasciamo che macOS pulisca al termine del processo,
    					-- ma dimostra la complessità della gestione manuale tra runtime diversi.
    				end
    			end
    		end

feature {NONE} -- Helper di diagnostica

	print_error (a_api: RRD_NATIVE_API)
			-- Recupera e stampa l'errore interno di RRDtool
		local
			err_ptr: POINTER
			c_str: C_STRING
		do
			err_ptr := a_api.rrd_get_error_c
			if err_ptr /= Void then
				create c_str.make_by_pointer (err_ptr)
				print ("Dettaglio errore RRDtool: " + c_str.string + "%N")
				a_api.rrd_clear_error_c
			end
		end

	estrai_double_da_matrice (a_base_ptr: POINTER; a_byte_offset: INTEGER): REAL_64
    			-- Legge un Double (REAL_64) situato a un determinato offset da un puntatore C grezzo.
    		external
    			"C inline"
    		alias
    			"return *(double *)((char *)$a_base_ptr + $a_byte_offset);"
    		end

invariant
	filename_presente: filename /= Void
	step_positivo: step > 0
end