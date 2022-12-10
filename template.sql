CREATE TABLE IF NOT EXISTS "singletons" (
  "nom"	STRING,
  "_data_"	BLOB,
  PRIMARY KEY("nom")
);

CREATE TABLE IF NOT EXISTS "gcvols" (
  "id"	INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id")
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS "tribus" (
  "id"	INTEGER,
  "v" INTEGER,
  "iv" INTEGER,
  "dh"  INTEGER,
  "dhb" INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id")
) WITHOUT ROWID;
CREATE INDEX "tribus_iv" ON "tribus" ( "iv" );
CREATE INDEX "tribus_dh" ON "tribus" ( "dh" );
CREATE INDEX "tribus_dhb" ON "tribus" ( "dhb" ) WHERE "dhb" > 0;

CREATE TABLE IF NOT EXISTS "comptas" (
  "id"	INTEGER,
  "v" INTEGER,
  "iv" INTEGER,
  "idt" INTEGER,
  "idtb" INTEGER,
  "hps1" INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id")
) WITHOUT ROWID;
CREATE INDEX "comptas_iv" ON "comptas" ( "iv" );
CREATE INDEX "comptas_idt" ON "comptas" ( "idt" );
CREATE INDEX "comptas_hps1" ON "comptas" ( "hps1" );

CREATE TABLE IF NOT EXISTS "avatars" (
  "id"	INTEGER,
  "v" INTEGER,
  "iv" INTEGER,
  "vcv" INTEGER,
  "ivc" INTEGER,
  "dds" INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id")
) WITHOUT ROWID;
CREATE INDEX "avatars_v" ON "avatars" ( "iv" );
CREATE INDEX "avatars_ivc" ON "avatars" ( "ivc" );
CREATE INDEX "avatars_dds" ON "avatars" ( "dds" );

CREATE TABLE IF NOT EXISTS "chats" (
  "id"	INTEGER,
  "ids"  INTEGER,
  "v" INTEGER,
  "iv" INTEGER,
  "ttl" INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id", "ids")
);
CREATE INDEX "chats_iv" ON "chats" ( "iv" );
CREATE INDEX "chats_ttl" ON "chats" ( "ttl" ) WHERE "ttl" > 0;

CREATE TABLE IF NOT EXISTS "secrets" (
  "id"	INTEGER,
  "ids"  INTEGER,
  "v" INTEGER,
  "iv" INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id", "ids")
);
CREATE INDEX "secrets_iv" ON "secrets" ( "iv" );

CREATE TABLE IF NOT EXISTS "transferts" (
  "id"	 INTEGER,
  "ids"  INTEGER,
  "dlv"  INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id", "ids")
);
CREATE INDEX "transferts_dlv" ON "transferts" ( "dlv" );

CREATE TABLE IF NOT EXISTS "rdvs" (
  "id"	 INTEGER,
  "ids"  INTEGER,
  "v"    INTEGER,
  "iv" INTEGER,
  "ttl"  INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id", "ids")
);
CREATE INDEX "rdvs_iv" ON "rdvs" ( "iv" );
CREATE INDEX "rdvs_ids" ON "rdvs" ( "ids" );
CREATE INDEX "rdvs_ttl" ON "rdvs" ( "ttl" );

CREATE TABLE IF NOT EXISTS "groupes" (
  "id"	INTEGER,
  "v"   INTEGER,
  "iv"  INTEGER,
  "dds" INTEGER,
  "dfh" INTEGER,
  "ttl" INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id")
) WITHOUT ROWID;
CREATE INDEX "groupes_iv" ON "groupes" ( "iv" );
CREATE INDEX "groupes_dfh" ON "groupes" ( "dfh" ) WHERE "dfh" > 0;
CREATE INDEX "groupes_ttl" ON "groupes" ( "ttl" ) WHERE "ttl" > 0;
CREATE INDEX "groupes_dds" ON "groupes" ( "dds" );

CREATE TABLE IF NOT EXISTS "membres" (
  "id"	INTEGER,
  "ids"  INTEGER,
  "v"  INTEGER,
  "iv" INTEGER,
  "_data_"	BLOB,
  PRIMARY KEY("id", "ids")
);
CREATE INDEX "membres_iv" ON "membres" ( "iv" );
