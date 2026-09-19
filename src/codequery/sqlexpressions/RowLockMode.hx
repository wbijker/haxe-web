package codequery.sqlexpressions;

/** What a statement locks of the rows it reads. */
enum RowLockMode {
	None;
	Update;
	NoKeyUpdate;
	Share;
	KeyShare;
}
