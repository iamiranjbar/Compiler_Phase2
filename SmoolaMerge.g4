grammar Smoola;
	@members{
	   void print(Object obj){
	        System.out.println(obj);
	   }
	}

	@header {
		import ast.node.Program;
		import ast.node.declaration.*;
		import ast.node.expression.*;
		import ast.VisitorImpl;
		import symbolTable.*;
		import java.util.Map;
		import java.util.Iterator;
		import java.util.Set;
		import java.util.HashMap;
	}
	
	program:
		program1[new SymbolTable(), 0]
		{
			print($program1.error_count);
			if ($program1.synthesized_table.getItemsSize() == 0 || $program1.error_count > 0) {
				if ($program1.synthesized_table.getItemsSize() == 0) {
					System.out.printf("Line:%d:No class exists in the program\n", $program1.start.getLine());	
				}
			} else {
				VisitorImpl visitor = new VisitorImpl();
				$program1.synthesized_type.accept(visitor);
			}
		}
	;

    program1 [SymbolTable inherited_table, int inherited_error_count] returns [int error_count, Program synthesized_type, SymbolTable synthesized_table]:
        {
        	$synthesized_type = new Program();
        }
        mainClass[new SymbolTable(inherited_table)]
        {
        	$synthesized_type.setMainClass($mainClass.synthesized_type);
        	try {
        		if ($mainClass.synthesized_name == null) {
        			throw new Exception();
        		}
        		$inherited_table.put(new SymbolTableClassItem($mainClass.synthesized_name, null, $mainClass.synthesized_table, $mainClass.start.getLine()));
        	}
        	catch(Exception e) {
        			
        	}
        }
        (
        	classDeclaration[inherited_error_count ,0, new SymbolTable(inherited_table)]
        	{
        		$inherited_error_count = $inherited_error_count + $classDeclaration.error_count;
        		$synthesized_type.addClass($classDeclaration.synthesized_type);
        		try{
        			$inherited_table.put(new SymbolTableClassItem($classDeclaration.synthesized_name, (($classDeclaration.synthesized_type.getParentName() != null) ? $classDeclaration.synthesized_type.getParentName().getName() : null), $classDeclaration.synthesized_table, $classDeclaration.start.getLine()));
        		}catch(ItemAlreadyExistsException e){
        			// add class with new name
        			$inherited_error_count++;
        			System.out.printf("Line:%d:Redefinition of class %s\n", $classDeclaration.start.getLine(), $classDeclaration.synthesized_name);
        		}
        	}
        )* {$synthesized_table = $inherited_table; $error_count = $inherited_error_count;}
        {
        	print("llllllll");
        	Iterator it = $synthesized_table.getItems().entrySet().iterator();
		    while (it.hasNext()) {
		        Map.Entry pair = (Map.Entry)it.next();
		        if (((SymbolTableClassItem)(pair.getValue())).getParentName() != null && ((SymbolTableClassItem)(pair.getValue())).getParentName() != "") {
		         	((SymbolTableClassItem)(pair.getValue())).setParent(((SymbolTableClassItem)($synthesized_table.getInCurrentScope(((SymbolTableClassItem)(pair.getValue())).getParentName()))).getSymbolTable());
		         	Iterator it2 = ((SymbolTableClassItem)(pair.getValue())).getSymbolTable().getItems().entrySet().iterator();
				    while (it2.hasNext()) {
				        Map.Entry pair2 = (Map.Entry)it2.next();
				        if (((SymbolTableClassItem)(pair.getValue())).getParentSymbolTable().getItems().containsKey(pair2.getKey())) {
				        	if (pair2.getValue() instanceof SymbolTableMethodItem) {
				        		$error_count++;
				        		System.out.printf("Line:%d:Redefinition of method ‬‬%s\n", ((SymbolTableMethodItem)(pair2.getValue())).getLine(), ((SymbolTableMethodItem)(pair2.getValue())).getName());
				        	} else {
				        		$error_count++;
				        		System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", ((SymbolTableVariableItemBase)(pair2.getValue())).getLine(), ((SymbolTableVariableItemBase)(pair2.getValue())).getName());
				        	}
				        }
					}
		    	}
        	}
        }
        EOF
    ;
    mainClass [SymbolTable inherited_table] returns [ClassDeclaration synthesized_type, SymbolTable synthesized_table, String synthesized_name]:
        // name should be checked later
        'class' name = ID '{' 'def' name1 = ID
        {
        	try {
        		if ($name1.getText() != null) {
        			$inherited_table.put(new SymbolTableMethodItem($name1.getText(),null,$name1.line));	
        		}	
        	}
        	catch(Exception e) {
        		
        	}
        } '(' ')' ':' 'int' '{'  statements 'return' expression ';' '}' '}' {$synthesized_type = new ClassDeclaration(new Identifier($name.getText()), null); $synthesized_name = $name.getText(); $synthesized_table = $inherited_table;}
    ;
    classDeclaration [int inherited_error_count, int inherited_index, SymbolTable inherited_table] returns [int error_count, ClassDeclaration synthesized_type, SymbolTable synthesized_table, String synthesized_name]:
        'class' name = ID ('extends' father_name = ID)? {$synthesized_type = new ClassDeclaration(new Identifier($name.getText()), (($father_name != null) ? new Identifier($father_name.getText()) : null));}'{' (varDeclaration
        	{
        		try {
        			if ($varDeclaration.synthesized_type != null) {
        				$synthesized_type.addVarDeclaration($varDeclaration.synthesized_type);
        				$inherited_table.put(new SymbolTableVariableItemBase($varDeclaration.synthesized_type.getIdentifier().getName(), $varDeclaration.synthesized_type.getType(), $inherited_index++, $varDeclaration.start.getLine()));
        			}
        		}
        		catch(Exception e) {
        			$inherited_error_count++;
        			System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", $varDeclaration.start.getLine(), $varDeclaration.synthesized_type.getIdentifier().getName());	
        		}
        		

        	})* (methodDeclaration[$inherited_error_count, $inherited_index, $inherited_table]
        	{
        		$inherited_error_count = $inherited_error_count + $methodDeclaration.error_count;
        		try {
	        		if ($methodDeclaration.synthesized_type.getName().getName() != null) {
	        			$synthesized_type.addMethodDeclaration($methodDeclaration.synthesized_type);
	        			$inherited_table.put(new SymbolTableMethodItem($methodDeclaration.synthesized_type.getName().getName(),/*$methodDeclaration.synthesized_type.getArgs()*/null, $methodDeclaration.start.getLine()));	
	        		}	
	        	}
	        	catch(Exception e) {
	        		$inherited_error_count++;
	        		System.out.printf("Line:%d:Redefinition of method ‬‬%s\n", $methodDeclaration.start.getLine(), $methodDeclaration.synthesized_type.getName().getName());	
	        	}
        	})* '}' {$synthesized_name = $name.getText(); $synthesized_table = $inherited_table; $error_count = $inherited_error_count;}
    ;
    varDeclaration returns [VarDeclaration synthesized_type]:
        'var' ID ':' type ';' {$synthesized_type = new VarDeclaration(new Identifier($ID.getText()), null);}
    ;
    methodDeclaration[int inherited_error_count, int inherited_index, SymbolTable inherited_table] returns [int error_count, SymbolTable synthesized_table, MethodDeclaration synthesized_type]:
        {$synthesized_table = new SymbolTable();}'def' name = ID ('(' ')' | ('(' ID ':' type (',' ID ':' type)* ')')) ':' type '{' {$synthesized_table.push(new SymbolTable(/*$inherited_table*/));} (varDeclaration
        {
        	try {
    			if ($varDeclaration.synthesized_type != null) {
    				$synthesized_table.put(new SymbolTableVariableItemBase($varDeclaration.synthesized_type.getIdentifier().getName(), $varDeclaration.synthesized_type.getType(), $inherited_index++, $varDeclaration.start.getLine()));
    			}
    		}
    		catch(Exception e) {
    			$inherited_error_count++;
    			System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", $varDeclaration.start.getLine(), $varDeclaration.synthesized_type.getIdentifier().getName());	
    		}
        })* statements {$inherited_error_count += $statements.error_count;} 'return' expression ';' {$synthesized_table.pop();}'}' {$synthesized_type = new MethodDeclaration(new Identifier($name.getText())); $error_count = $inherited_error_count;}
    ;
    statements returns [int error_count]:
       {$error_count = 0;} (statement {$error_count += $statement.error_count;})*
    ;
    statement returns [int error_count]:
    	{$error_count = 0;}
        statementBlock |
        statementCondition |
        statementLoop |
        statementWrite |
        statementAssignment {$error_count = $statementAssignment.error_count;}
    ;
    statementBlock:
        '{'  statements '}'
    ;
    statementCondition:
        'if' '('expression')' 'then' statement ('else' statement)?
    ;
    statementLoop:
        'while' '(' expression ')' statement
    ;
    statementWrite:
        'writeln(' expression ')' ';'
    ;
    statementAssignment returns [int error_count]:
        expression ';' {$error_count = $expression.error_count;}
    ;

    expression returns [int error_count]:
		expressionAssignment {$error_count = $expressionAssignment.error_count;}
	;

    expressionAssignment returns [int error_count]:
		expressionOr '=' expressionAssignment {$error_count = $expressionAssignment.error_count;}
	    |	expressionOr {$error_count = $expressionOr.error_count;}
	;

    expressionOr returns [int error_count]:
		expressionAnd expressionOrTemp {$error_count = $expressionAnd.error_count;}
	;

    expressionOrTemp:
		'||' expressionAnd expressionOrTemp
	    |
	;

    expressionAnd returns [int error_count]:
		expressionEq expressionAndTemp {$error_count = $expressionEq.error_count;}
	;

    expressionAndTemp:
		'&&' expressionEq expressionAndTemp
	    |
	;

    expressionEq returns [int error_count]:
		expressionCmp expressionEqTemp {$error_count = $expressionCmp.error_count;}
	;

    expressionEqTemp:
		('==' | '<>') expressionCmp expressionEqTemp
	    |
	;

    expressionCmp returns [int error_count]:
		expressionAdd expressionCmpTemp {$error_count = $expressionAdd.error_count;}
	;

    expressionCmpTemp:
		('<' | '>') expressionAdd expressionCmpTemp
	    |
	;

    expressionAdd returns [int error_count]:
		expressionMult expressionAddTemp {$error_count = $expressionMult.error_count;}
	;

    expressionAddTemp:
		('+' | '-') expressionMult expressionAddTemp
	    |
	;

    expressionMult returns [int error_count]:
		expressionUnary expressionMultTemp {$error_count = $expressionUnary.error_count;}
	;

    expressionMultTemp:
		('*' | '/') expressionUnary expressionMultTemp
	    |
	;

    expressionUnary returns [int error_count]:
		('!' | '-') expressionUnary {$error_count = 0;}
	    |	expressionMem {$error_count = $expressionMem.error_count;}
	;

    expressionMem returns [int error_count]:
		expressionMethods expressionMemTemp {$error_count = $expressionMethods.error_count;}
	;

    expressionMemTemp:
		'[' expression ']'
	    |
	;
	expressionMethods returns[int error_count]:
	    expressionOther expressionMethodsTemp {$error_count = $expressionOther.error_count;}
	;
	expressionMethodsTemp:
	    '.' (ID '(' ')' | ID '(' (expression (',' expression)*) ')' | 'length') expressionMethodsTemp
	    |
	;
    expressionOther returns [int error_count]:
    	{$error_count = 0;}
		CONST_NUM
        |	CONST_STR
        |   'new ' 'int' '[' index = CONST_NUM ']' 
        {
        	if (Integer.parseInt($index.text) <= 0) {
        		$error_count = 1;
        		System.out.printf("Line:%d:Array length should not be zero or negative\n", $index.getLine());
        	}
        }
        |   'new ' ID '(' ')'
        |   'this'
        |   'true'
        |   'false'
        |	ID
        |   ID '[' expression ']'
        |	'(' expression ')'
	;
	type:
	    'int' |
	    'boolean' |
	    'string' |
	    'int' '[' ']' |
	    ID
	;
    CONST_NUM:
		[0-9]+
	;

    CONST_STR:
		'"' ~('\r' | '\n' | '"')* '"'
	;
    NL:
		'\r'? '\n' -> skip
	;

    ID:
		[a-zA-Z_][a-zA-Z0-9_]*
	;

    COMMENT:
		'#'(~[\r\n])* -> skip
	;

    WS:
    	[ \t] -> skip
    ;