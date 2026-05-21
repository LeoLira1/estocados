CREATE TABLE `estocados_cooperados` (
	`id` integer PRIMARY KEY AUTOINCREMENT,
	`produto` text NOT NULL,
	`cooperado` text NOT NULL,
	`quantidade` integer DEFAULT 0 NOT NULL,
	`data_entrada` text NOT NULL,
	`observacao` text DEFAULT '',
	`ativo` integer DEFAULT 1
);

-- demais tabelas conforme estrutura fornecida pelo usuário
