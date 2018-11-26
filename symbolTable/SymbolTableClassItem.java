package symbolTable;

//import SymbolTable.SymbolTable;

import java.util.ArrayList;

public class SymbolTableClassItem extends SymbolTableItem {

    SymbolTable symbolTable;
    SymbolTable parent;
    String parentName;

    public SymbolTableClassItem(String name, String parent, SymbolTable symbolTable, int line) {
        this.name = name;
        this.symbolTable = symbolTable;
        this.parentName = parent;
        this.line = line;
    }

    public void setParent(SymbolTable parent) {
        this.parent = parent;
    }

    public SymbolTable getParentSymbolTable() {
        return parent;
    }

    public String getParentName() {
        return parentName;
    }

    public SymbolTable getSymbolTable() {
        return symbolTable;
    }

    @Override
    public String getKey() {
        return name;
    }
}
