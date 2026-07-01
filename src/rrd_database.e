note
	description: "Rappresentazione logica di un file RRD e delle operazioni su di esso"

class
	RRD_DATABASE

create
	make

feature {NONE} -- Inizializzazione

	make (a_filename: STRING; a_step: INTEGER)
			-- Crea un'istanza logica del database associata a un file.
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
			-- Percorso del file sul filesystem

	step: INTEGER
			-- Intervallo di campionamento base (in secondi)

	data_sources: LIST [RRD_DATA_SOURCE]
			-- Elenco delle sorgenti associate

	archives: LIST [RRD_ARCHIVE]
			-- Elenco degli archivi associati

feature -- Operazioni di configurazione

	add_data_source (a_ds: RRD_DATA_SOURCE)
			-- Aggiunge una sorgente dati alla configurazione.
		require
			ds_presente: a_ds /= Void
		do
			data_sources.extend (a_ds)
		ensure
			aggiunto: data_sources.count = old data_sources.count + 1
		end

	add_archive (a_rra: RRD_ARCHIVE)
			-- Aggiunge un archivio alla configurazione.
		require
			rra_presente: a_rra /= Void
		do
			archives.extend (a_rra)
		ensure
			aggiunto: archives.count = old archives.count + 1
		end

feature -- Interfaccia dei comandi (Verso il wrapper C)

	create_on_disk
			-- Crea fisicamente il file RRD eseguendo il binding.
		require
			ha_ds: not data_sources.is_empty
			ha_rra: not archives.is_empty
		do
			-- TODO: Qui chiameremo il wrapper C passando un array di stringhe
			print ("Chiamata a rrd_create per il file: " + filename + "%N")
		end

invariant
	filename_presente: filename /= Void
	step_positivo: step > 0
end