package symbolTable;

import ast.Type.Type;

public abstract class SymbolTableItem {
	protected String name;
	protected int line;

	public SymbolTableItem() {
	}

	public int getLine() {
		return line;
	}

	public abstract String getKey();

}
