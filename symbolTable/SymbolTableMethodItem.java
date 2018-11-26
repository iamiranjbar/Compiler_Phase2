package symbolTable;

import ast.Type.Type;

import java.util.ArrayList;

public class SymbolTableMethodItem extends SymbolTableItem {

    ArrayList<Type> argTypes = new ArrayList<>();

    public SymbolTableMethodItem(String name, ArrayList<Type> argTypes, int line) {
        this.name = name;
        this.argTypes = argTypes;
        this.line = line;
    }

    public String getName() {
        return name;
    }

    @Override
    public String getKey() {
        //todo
        return name;
    }
}
