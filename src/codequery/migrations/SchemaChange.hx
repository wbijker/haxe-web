package codequery.migrations;

/**
	One difference between two schemas.

	A migration is a list of these, and each knows how to be undone — which is what lets a
	migration be written with its reverse beside it rather than guessed at later.
**/
enum SchemaChange {
	CreateTable(table:DatabaseTableDefinition);
	DropTable(table:DatabaseTableDefinition);
	AddColumn(table:String, column:DatabaseColumnDefinition);
	DropColumn(table:String, column:DatabaseColumnDefinition);
	AlterColumn(table:String, from:DatabaseColumnDefinition, to:DatabaseColumnDefinition);
}
