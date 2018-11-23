package symbolTable;

//import SymbolTable.SymbolTable;

import java.util.ArrayList;

public class SymbolTableClassItem extends SymbolTableItem {

    SymbolTable symbolTable;

    public SymbolTableClassItem(String name, SymbolTable symbolTable) {
        this.name = name;
        this.symbolTable = symbolTable;
    }

    @Override
    public String getKey() {
        return name;
    }
}
