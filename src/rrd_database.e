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

invariant
	filename_presente: filename /= Void
	step_positivo: step > 0
end